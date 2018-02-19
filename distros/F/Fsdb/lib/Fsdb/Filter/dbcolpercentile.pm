#!/usr/bin/perl

#
# dbcolpercentile.pm
# Copyright (C) 1997-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolpercentile;

=head1 NAME

dbcolpercentile - compute percentiles or ranks for an existing column

=head1 SYNOPSIS

    dbcolpercentile [-rplhS] column

=head1 DESCRIPTION

Compute a percentile of a column of numbers.
The new column will be called I<percentile> or I<rank>.
Non-numeric records are handled as in other programs.

If the data is pre-sorted and only a rank is requested,
no extra storage is required.
In all other cases, a full copy of data is buffered on disk.

=head1 OPTIONS

=over 4

=item B<-p> or B<--percentile>

Show percentile (default).

=item B<-P> or B<--rank> or B<--nopercentile>

Compute ranks instead of percentiles.

=item B<--fraction>

Show fraction (percentage, except between 0 and 1, not cumulative fraction).

=item B<-a> or B<--include-non-numeric>

Compute stats over all records (treat non-numeric records
as zero rather than just ignoring them).

=item B<-S> or B<--pre-sorted>

Assume data is already sorted.
With one -S, we check and confirm this precondition.
When repeated, we skip the check.

=item B<-f FORMAT> or B<--format FORMAT>

Specify a L<printf(3)>-style format for output statistics.
Defaults to C<%.5g>.

=item B<-T TmpDir>

where to put tmp files.
Also uses environment variable TMPDIR, if -T is 
not specified.
Default is /tmp.

=back

Sort specification options (can be interspersed with column names):

=over 4

=item B<-r> or B<--descending>

sort in reverse order (high to low)

=item B<-R> or B<--ascending>

sort in normal order (low to high)

=item B<-n> or B<--numeric>

sort numerically (default)

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

=item B<--help>

Show help.

=item B<--man>

Show full manual.

=back

=for comment
end_standard_fsdb_options


=head1 SAMPLE USAGE

=head2 Input:

    #fsdb name id test1
    a 1 80
    b 2 70
    c 3 65
    d 4 90
    e 5 70
    f 6 90

=head2 Command:

    cat DATA/grades.fsdb | dbcolpercentile test1

=head2 Output:

	#fsdb name id test1 percentile
	d	4	90	1
	f	6	90	1
	a	1	80	0.66667
	b	2	70	0.5
	e	5	70	0.5
	c	3	65	0.16667
	#  | dbsort -n test1
	#   | dbcolpercentile test1

=head2 Command 2:

    cat DATA/grades.fsdb | dbcolpercentile --rank test1

=head2 Output 2:

	#fsdb name id test1 rank
	d	4	90	1
	f	6	90	1
	a	1	80	3
	b	2	70	4
	e	5	70	4
	c	3	65	6
	#  | dbsort -n test1
	#   | dbcolpercentile --rank test1


=head1 SEE ALSO

L<Fsdb>.
L<dbcolhisto>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;


use Fsdb::Filter;
use Fsdb::Filter::dbpipeline qw(dbpipeline_filter dbsort);
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;
use Fsdb::Support qw($is_numeric_regexp);
use Fsdb::Support::NamedTmpfile;


=head2 new

    $filter = new Fsdb::Filter::dbcolpercentile(@arguments);

Create a new dbcolpercentile object, taking command-line arguments.

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
    my($self) = @_;
    $self->SUPER::set_defaults();
    $self->{_mode} = 'percentile';
    $self->{_sort_order} = undef;
    $self->{_sort_as_numeric} = 1;
    $self->{_include_non_numeric} = undef;
    $self->{_pre_sorted} = 0;
    $self->{_target_column} = undef;
    $self->{_save_in_filename} = undef;
    $self->{_format} = "%.5g";
    $self->set_default_tmpdir;
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
	'a|include-non-numeric!' => \$self->{_include_non_numeric},
	'autorun!' => \$self->{_autorun},
	'd|debug+' => \$self->{_debug},
	'f|format=s' => \$self->{_format},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'fraction' => sub { $self->{_mode} = 'fraction'; },
	'p|percentile' => sub { $self->{_mode} = 'percentile'; },
	'P|nopercentile|rank' => sub { $self->{_mode} = 'rank'; },
	'S|pre-sorted+' => \$self->{_pre_sorted},
	'T|tmpdir|tempdir=s' => \$self->{_tmpdir},
	# sort key options:
	'n|numeric' => sub { $self->{_sort_as_numeric} = 1; },
	'N|lexical' => sub { $self->{_sort_as_numeric} = undef; },
	'r|descending' => sub { $self->{_sort_order} = -1; },
	'R|ascending' => sub { $self->{_sort_order} = 1; },
	) or pod2usage(2);
    $self->parse_target_column(\@argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    # assign default sort order, if not specified
    if (!defined($self->{_sort_order})) {
	$self->{_sort_order} = -1;
	warn "defaulting sort order to " . ($self->{_sort_order} == 1 ? "ascending" : "descending") . "\n" if ($self->{_debug});
    };

    #
    # input
    #
    # guarantee data is sorted
    # (swap reader if necessary)
    if ($self->{_pre_sorted}) {
	# pre-sorted, so just read it
	$self->finish_io_option('input', -comment_handler => $self->create_delay_comments_sub);
	$self->{_sorter_fred} = undef;
    } else {
	# not sorted, so sort it and read that
	my @sort_args = ('--nolog', $self->{_target_column});
	unshift(@sort_args, '--descending') if ($self->{_sort_order} == -1);
	unshift(@sort_args, ($self->{_sort_as_numeric} ? '--numeric' : '--lexical'));
	my($new_reader, $new_fred) = dbpipeline_filter($self->{_input}, [-comment_handler => $self->create_delay_comments_sub], dbsort(@sort_args));
	$self->{_pre_sorted_input} = $self->{_input};
	$self->{_in} = $new_reader;
	$self->{_sorter_fred} = $new_fred;
    };
    $self->{_target_coli} = $self->{_in}->col_to_i($self->{_target_column});
    croak($self->{_prog} . ": target column " . $self->{_target_column} . " is not in input stream.\n")
	if (!defined($self->{_target_coli}));

    #
    # output
    #
    $self->{_destination_column} = $self->{_mode};
    croak($self->{_prog} . ": internal error: bad rank mode\n")
	if (!defined($self->{_destination_column}));

    $self->finish_io_option('output', -clone => $self->{_in}, -outputheader => 'delay');
    $self->{_out}->col_create($self->{_destination_column})
	or croak($self->{_prog} . ": cannot create column '" . $self->{_destination_column} . "' (maybe it already existed?)\n");
    $self->{_destination_coli} = $self->{_out}->col_to_i($self->{_destination_column});
}

=head2 _count_rows

    $n = $self->_count_rows()

Interpose a filter on C<$self->{_in}> that counts the rows.

=cut
sub _count_rows() {
    my($self) = shift @_;

    my $orig_in = $self->{_in};
    $self->{_save_in_filename} = Fsdb::Support::NamedTmpfile::alloc($self->{_tmpdir});
    my($save_sink) = new Fsdb::IO::Writer(-file => $self->{_save_in_filename}, -clone => $orig_in);
    my($n) = 0;
    my $read_fastpath_sub = $orig_in->fastpath_sub();
    my $write_fastpath_sub = $save_sink->fastpath_sub();
    my $fref;
    while ($fref = &$read_fastpath_sub()) {
	$n++;
	&$write_fastpath_sub($fref);
    };
    $save_sink->error and croak($self->{_prog} . ": error writing temporary file.\n");
    $save_sink->close;

    # reopen _in with our saved data
    $self->{_in} = new Fsdb::IO::Reader(-file => $self->{_save_in_filename});
    return $n;
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $percentile_scaling = 1;
    my $n;
    if ($self->{_mode} eq 'percentile') {
	$n = $self->_count_rows;
        $percentile_scaling = 1.0 / $n;
    };

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();
    my $fref;
    my($mode) = $self->{_mode};
    my $i = ($mode eq 'rank' ? 1 : 0);
    my $result;  # this row
    my $last = undef;
    my $in_run = undef;
    my $run_i = undef;
    my $x;
    my($xf) = $self->{_target_coli};
    my($of) = $self->{_destination_coli};
    my($check_sort_order) = ($self->{_pre_sorted} == 1) ? $self->{_sort_order} : undef;
    warn "will check sort order for " . $self->{_sort_order} . ".\n" if ($self->{_debugt} && $check_sort_order);

    while ($fref = &$read_fastpath_sub()) {

        $x = $fref->[$xf];
	$result = $i++;
	if ($mode eq 'percentile') {
	    $result = ($n - $result) * $percentile_scaling;
	    $result = $self->numeric_formatting($result);
	};

	if ($x !~ /$is_numeric_regexp/) {
	    $last = undef;   # non-numeric always ends run
	} else {
	    # check for runs
	    if (defined($last) && $x == $last) {
		# in a run
		$result = $run_i;
		$in_run = 1;
	    } else {
		# sanity check
		if ($check_sort_order) {
		    if (defined($last)) {
		        my $order = ($x <=> $last);
			croak($self->{_prog} . ": data out of order between $last and $x, should be in " . ($check_sort_order == -1 ? "descending" : "ascending") . " order.\n")
			    if ($order != $check_sort_order);
		    };
		};
		# change
		$last = $x;
		$in_run = undef;
	    };
	};

	$fref->[$of] = $result;
	$run_i = $result if (! $in_run);

	&$write_fastpath_sub($fref);
    };

    if (defined($self->{_sorter_fred})) {
	$self->{_sorter_fred}->join();
	$self->{_sorter_fred} = undef;
    };
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
