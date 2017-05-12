#!/usr/bin/perl -w

#
# dbsort.pm
# Copyright (C) 1991-2016 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbsort;

=head1 NAME

dbsort - sort rows based on the the specified columns

=head1 SYNOPSIS

    dbsort [-M MemLimit] [-T TemporaryDirectory] [-nNrR] column [column...]

=head1 DESCRIPTION

Sort all input rows as specified by the numeric or lexical columns.

Dbsort consumes a fixed amount of memory regardless of input size.
(It reverts to temporary files on disk if necessary, based on the -M
and -T options.)

The sort should be stable, but this has not yet been verified.

For large inputs (those that spill to disk),
L<dbsort> will do some of the merging in parallel, if possible.
The B<--parallel> option can control the degree of parallelism,
if desired.

=head1 OPTIONS

General option:

=over 4

=item B<-M MaxMemBytes>

Specify an approximate limit on memory usage (in bytes).
Larger values allow faster sorting because more operations
happen in-memory, provided you have enough memory.

=item B<-T TmpDir>

where to put tmp files.
Also uses environment variable TMPDIR, if -T is 
not specified.
Default is /tmp.

=item B<--parallelism N> or B<-j N>  

Allow up to N merges to happen in parallel.
Default is the number of CPUs in the machine.

=back

Sort specification options (can be interspersed with column names):

=over 4

=item B<-r> or B<--descending>

sort in reverse order (high to low)

=item B<-R> or B<--ascending>

sort in normal order (low to high)

=item B<-n> or B<--numeric>

sort numerically

=item B<-N> or B<--lexical>

sort lexicographically

=back

=for comment
begin_standard_fsdb_options

This module also supports the standard fsdb options:

=over 4

=item B<-d>

Enable debugging output.

=item B<-i> or B<--input> InputSource

Read from InputSource, typically a file name, or C<-> for standard input,
or (if in Perl) a IO::Handle, Fsdb::IO or Fsdb::BoundedQueue objects.

=item B<-o> or B<--output> OutputDestination

Write to OutputDestination, typically a file name, or C<-> for standard output,
or (if in Perl) a IO::Handle, Fsdb::IO or Fsdb::BoundedQueue objects.

=item B<--autorun> or B<--noautorun>

By default, programs process automatically,
but Fsdb::Filter objects in Perl do not run until you invoke
the run() method.
The C<--(no)autorun> option controls that behavior within Perl.

=item B<--header H>

Use H as the full Fsdb header, rather than reading a header from
then input.

=item B<--help>

Show help.

=item B<--man>

Show full manual.

=back

=for comment
end_standard_fsdb_options


=head1 SAMPLE USAGE

=head2 Input:

    #fsdb cid cname
    10 pascal
    11 numanal
    12 os

=head2 Command:

    cat data.fsdb | dbsort cname

=head2 Output:

    #fsdb      cid     cname
    11 numanal
    12 os
    10 pascal
    #  | dbsort cname

=head1 SEE ALSO

L<dbmerge(1)>,
L<dbmapreduce(1)>,
L<Fsdb(3)>

=head1 CLASS FUNCTIONS

=cut


@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::IO::Reader;
use Fsdb::IO::Writer;
use Fsdb::Filter;
use Fsdb::Support::NamedTmpfile;
use Fsdb::Filter::dbmerge;
use Fsdb::Filter::dbpipeline qw(dbpipeline_sink dbmerge);

my($PERL_MEM_OVERHEAD) = 50;  # approx. bytes of overhead for each record in mem
my($PERL_MEM_SCALING) = 2;    # divided user requested mem by this factor to account to perl memory usage (huge approximatation)


=head2 new

    $filter = new Fsdb::Filter::dbsort(@arguments);

Create a new object, taking command-line arguments.

=cut

sub new ($@) {
    my $class = shift @_;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;
    $self->set_defaults;
    $self->parse_options(@_);
    $self->SUPER::post_new();
    return $self;
}


=head2 set_defaults

    $filter->set_defaults();

Internal: set up defaults.

=cut

sub set_defaults ($) {
    my $self = shift @_;
    $self->SUPER::set_defaults();
    $self->{_max_memory} = 1024*1024*256;
    $self->{_mem_debug} = undef;
    $self->{_sort_argv} = [];
    $self->set_default_tmpdir;
    $self->{_max_parallelism} = undef;
    $self->{_header} = undef;
}

=head2 parse_options

    $filter->parse_options(@ARGV);

Internal: parse command-line arguments.

=cut

sub parse_options ($@) {
    my $self = shift @_;

    my(@argv) = @_;
    $self->get_options(
	\@argv,
 	'help|?' => sub { pod2usage(1); },
	'man' => sub { pod2usage(-verbose => 2); },
	'autorun!' => \$self->{_autorun},
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'header=s' => \$self->{_header},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'j|parallelism=i' => \$self->{_max_parallelism},
	'log!' => \$self->{_logprog},
	'M|maxmemory=i' => \$self->{_max_memory},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'T|tmpdir|tempdir=s' => \$self->{_tmpdir},
	# sort key options:
	'n|numeric' => sub { $self->parse_sort_option(@_); },
	'N|lexical' => sub { $self->parse_sort_option(@_); },
	'r|descending' => sub { $self->parse_sort_option(@_); },
	'R|ascending' => sub { $self->parse_sort_option(@_); },
	'<>' => sub { $self->parse_sort_option('<>', @_); },
	) or pod2usage(2);
    croak $self->{_prog} . ": internal error, extra arguments.\n"
	if ($#argv != -1);
}


=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup($) {
    my($self) = @_;

    croak $self->{_prog} . ": no sorting key specified.\n"
	if ($self->{_sort_argv} == -1);

    #
    # setup final IO
    #
    my(@finish_args) = (-comment_handler => $self->create_delay_comments_sub);
    push (@finish_args, -header => $self->{_header}) if (defined($self->{_header}));
    $self->finish_io_option('input', @finish_args);

    $self->{_compare_code} = $self->create_compare_code($self->{_in}, $self->{_in});
    croak $self->{_prog} . ": no sort field specified.\n"
	if (!defined($self->{_compare_code}));
    print "COMPARE CODE:\n\t" . $self->{_compare_code} . "\n" if ($self->{_debug});
    my $compare_sub;
    eval '$self->{_compare_sub} = $compare_sub = ' . $self->{_compare_code} . ';';
    $@ && croak $self->{_prog} . ":  internal eval error in compare code: $@.\n";
#    $@ && croak "dbsort.pm:  internal eval error in compare code: $@.\n";
}

=head2 segment_start

    $self->segment_start(\@rows);

Sorting happens internally,
to handle large things in pieces if necessary.

call C<$self->segment_start> to init things and to restart after an overflow
C<$self->segment_overflow> to close one segment and start the next,
and C<$self->segment_merge_finish> to put them back together again.

Note that we don't invoke the merge code unless the data
exceeds some threshold size, so small sorts happen completely
in memory.

Once we give up on memory, all the merging happens by making
passes over the disk files.

=cut

sub segment_start ($\@) {
    my ($self, $rows_ref) =  @_;

    $#{$rows_ref} = -1;  # truncate array
}

=head2 segment_next_output

    $out = $self->segment_next_output($input_finished)

Internal: return a Fsdb::IO::Writer as $OUT
that either points to our output or a temporary file, 
depending on how things are going.

=cut

sub segment_next_output($$) {
    my ($self, $input_finished) = @_;
    my $final_output = ($#{$self->{_files_to_merge}} == -1 && $input_finished);
    my $out;
    if ($final_output) {
	if (!defined($self->{_merge_fred})) {
	    # setup output
	    # (if merging, then we did this when we forked the merge thread)
	    $self->finish_io_option('output', -clone => $self->{_in});
	};
        $out = $self->{_out};
	print "# dbsort segment_next_output: final output\n" if ($self->{_debug});
    } else {
	# dump to a file for merging
	my $tmpfile = Fsdb::Support::NamedTmpfile::alloc($self->{_tmpdir});
	$out = $tmpfile;   # just return the name
	push(@{$self->{_files_to_merge}}, $tmpfile);
	print "# dbsort segment_next_output: intermediate file: $tmpfile\n" if ($self->{_debug});
    };
    return ($out, $final_output);
}

=head2 segment_overflow

    $self->segment_overflow(\@rows, $input_finished)

Called to sort @ROWS, writing them to the appropriate place.
$INPUT_FINISHED is set if all input has been read.

=cut

#sub so1 {
#    my ($self, $rows_ref) = @_;
#    my(@sorted_rows) = sort { $a->[0] <=> $b->[0] } @{$rows_ref};
#    return @sorted_rows;
#}

sub segment_overflow($\@$) {
    my($self, $rows_ref, $input_finished) = @_;

    my $compare_sub = $self->{_compare_sub};
    my(@sorted_rows) = sort $compare_sub @{$rows_ref};
#    my(@sorted_rows) = $self->so1($rows_ref);

    my ($out_fn, $final_output) = $self->segment_next_output($input_finished, 'Fsdb:IO');
    my $out;
    if (ref($out_fn) =~ /^Fsdb::IO::Writer/) {
	die "dbsort segment_overflow: suprise writer and NOT final_output\n"
	    if (!$final_output);
	$out = $out_fn;   # a bit hacky, but whatever
    } else {
	die "dbsort segment_overflow: suprise filename and final_output\n"
	    if ($final_output);
	$out = new Fsdb::IO::Writer(-file => $out_fn, -clone => $self->{_in});
    };

    my $write_fastpath_sub = $out->fastpath_sub;
    foreach (@sorted_rows) {
	&$write_fastpath_sub($_);
    };

    if (!$final_output) {
	$out->close;
	$self->segment_merge_start($out_fn);
	$self->segment_start($rows_ref);
    };
}

=head2 segment_merge_start

    $self->segment_merge_start($fn);

Start merging on file $FN.
Fork off a merge thread, if necessary.

=cut
sub segment_merge_start($$) {
    my($self, $fn) = @_;

    if (!defined($self->{_merge_fred})) {
	# create our output so we can give it to merge-thread
	$self->finish_io_option('output', -clone => $self->{_in}); # , -outputheader => 'never');

	print "# forking merge thread\n" if ($self->{_debug});
	my(@writer_args) = (-cols => [qw(filename)], -autoflush => 1);
	my(@merge_args) = qw(--nolog --noclose --removeinputs --xargs);
	push(@merge_args, '--parallelism', $self->{_max_parallelism})
	    if (defined($self->{_max_parallelism}));
	push(@merge_args, '-T', $self->{_tmpdir})
	    if (defined($self->{_tmpdir}));
	push(@merge_args, @{$self->{_sort_argv}});

	my($writer, $merge_fred) = dbpipeline_sink(\@writer_args,
	    '--output' => $self->{_out},
	    dbmerge(@merge_args));
	croak "dbsort: internal error in invoking dbmerge\n"
	    if (!defined($writer) || !defined($merge_fred));
	$self->{_merge_writer} = $writer;
	$self->{_merge_fred} = $merge_fred;
    };
    print "# dbsort segment_merge_start: sending merge thread: $fn\n" if ($self->{_debug});
    $self->{_merge_writer}->write_row($fn);
}


=head2 segment_merge_finish

    $self->segment_merge_finish();

Merge queued files, if any.
Just call L<dbmerge(1)> to do all the real work.

=cut

sub segment_merge_finish($) {
    my($self) = @_;
    return if (!defined($self->{_merge_fred}));
    return if ($#{$self->{_files_to_merge}} == -1);

    print "# final output\n" if ($self->{_debug});
    # tell it we're done
    $self->{_merge_writer}->close();	
    # and make it do its work
    $self->{_merge_fred}->join();
    $self->{_merge_fred} = undef;
}


=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    #
    # read in and set up the data
    #
    $self->{_files_to_merge} = [];
    my $read_fastpath_sub = $self->{_in}->fastpath_sub();

    my $fref;    # the current row
    my @rows;      # an array of frefs for each row, $i long
    my $memory_used = 0;
    my $scaled_max_memory =  int($self->{_max_memory} / (1.0 * $PERL_MEM_SCALING));
    my $row_mem_overhead = $PERL_MEM_OVERHEAD * ($#{$self->{_in}->cols} + 2);
    
    $self->segment_start(\@rows);
my $i = 0;
    while ($fref = &$read_fastpath_sub) {
	push (@rows, $fref);
	$memory_used += $row_mem_overhead;
	foreach (@$fref) {
	    $memory_used += length($_);
	};
	if ($memory_used > $scaled_max_memory) {
	    $self->segment_overflow(\@rows);
	    $memory_used = 0;
	};
    };
    # handle end case
    $self->segment_overflow(\@rows, 1) if ($#rows > -1);   # (spill any records in queued)
    # merge, if necessary
    $self->segment_merge_finish();
    # handle the null case: no output
    if ($#rows == -1 && $#{$self->{_files_to_merge}} == -1) {
	# open _out, just so we can log ourselves in finish()
	$self->finish_io_option('output', -clone => $self->{_in});
    };
};
    


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
