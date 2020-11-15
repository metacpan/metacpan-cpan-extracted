#!/usr/bin/perl -w

#
# dbmerge.pm
# Copyright (C) 1991-2020 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbmerge;

=head1 NAME

dbmerge - merge all inputs in sorted order based on the the specified columns

=head1 SYNOPSIS

    dbmerge --input A.fsdb --input B.fsdb [-T TemporaryDirectory] [-nNrR] column [column...]

or
    cat A.fsdb | dbmerge --input - --input B.fsdb [-T TemporaryDirectory] [-nNrR] column [column...]


or
    dbmerge [-T TemporaryDirectory] [-nNrR] column [column...] --inputs A.fsdb [B.fsdb ...]

or
    { echo "A.fsdb"; echo "B.fsdb" } | dbmerge --xargs column [column...]

=head1 DESCRIPTION

Merge all provided, pre-sorted input files, producing one sorted result.
Inputs can both be specified with C<--input>, or one can come
from standard input and the other from C<--input>.
With C<--xargs>, each line of standard input is a filename for input.

Inputs must have identical schemas (columns, column order,
and field separators).

Unlike F<dbmerge2>, F<dbmerge> supports an arbitrary number of 
input files.

Because this program is intended to merge multiple sources,
it does I<not> default to reading from standard input.
If you wish to list F<-> as an explicit input source.

Also, because we deal with multiple input files,
this module doesn't output anything until it's run.

L<dbmerge> consumes a fixed amount of memory regardless of input size.
It therefore buffers output on disk as necessary.
(Merging is implemented a series of two-way merges,
so disk space is O(number of records).)

L<dbmerge> will merge data in parallel, if possible.
The C<--parallelism> option can control the degree of parallelism,
if desired.


=head1 OPTIONS

General option:

=over 4

=item B<--xargs>

Expect that input filenames are given, one-per-line, on standard input.
(In this case, merging can start incrementally.)

=item B<--removeinputs>

Delete the source files after they have been consumed.
(Defaults off, leaving the inputs in place.)

=item B<-T TmpDir>

where to put tmp files.
Also uses environment variable TMPDIR, if -T is 
not specified.
Default is /tmp.

=item B<--parallelism N> or B<-j N>

Allow up to N merges to happen in parallel.
Default is the number of CPUs in the machine.

=item B<--endgame> (or B<--noendgame>)

Enable endgame mode, extra parallelism when finishing up.
(On by default.)

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

=item B<--header> H

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

File F<a.fsdb>:

    #fsdb cid cname
    11 numanal
    10 pascal

File F<b.fsdb>:

    #fsdb cid cname
    12 os
    13 statistics

These two files are both sorted by C<cname>,
and they have identical schemas.

=head2 Command:

    dbmerge --input a.fsdb --input b.fsdb cname

or

    cat a.fsdb | dbmerge --input b.fsdb cname

=head2 Output:

    #fsdb      cid     cname
    11 numanal
    12 os
    10 pascal
    13 statistics
    #  | dbmerge --input a.fsdb --input b.fsdb cname

=head1 SEE ALSO

L<dbmerge2(1)>,
L<dbsort(1)>,
L<Fsdb(3)>

=head1 CLASS FUNCTIONS

=cut


@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use 5.010;
use strict;
use Pod::Usage;
use Carp qw(croak carp);

use IO::Pipe;
use IO::Select;

use Fsdb::Filter;
use Fsdb::Filter::dbmerge2;
use Fsdb::Filter::dbcol;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;
use Fsdb::Support::NamedTmpfile;
use Fsdb::Support::OS;
use Fsdb::Support::Freds;


=head2 new

    $filter = new Fsdb::Filter::dbmerge(@arguments);

Create a new object, taking command-line arguments.

=cut

sub new($@) {
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

sub set_defaults($) {
    my $self = shift @_;
    $self->SUPER::set_defaults();
    $self->{_remove_inputs} = undef;
    $self->{_info}{input_count} = 2;
    $self->{_sort_argv} = [];
    $self->{_max_parallelism} = undef;
    $self->{_parallelism_available} = undef;
    $self->{_test} = '';
    $self->{_xargs} = undef;
    $self->{_endgame} = 1;
    $self->set_default_tmpdir;
    $self->{_header} = undef;
}

=head2 parse_options

    $filter->parse_options(@ARGV);

Internal: parse command-line arguments.

=cut

sub parse_options($@) {
    my $self = shift @_;

    my(@argv) = @_;
    my $past_sort_options = undef;
    $self->get_options(
	\@argv,
 	'help|?' => sub { pod2usage(1); },
	'man' => sub { pod2usage(-verbose => 2); },
	'autorun!' => \$self->{_autorun},
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'endgame!' => \$self->{_endgame},
	'header=s' => \$self->{_header},
	'i|input=s@' => sub { $self->parse_io_option('inputs', @_); },
	'inputs!' => \$past_sort_options,
	'j|parallelism=i' => \$self->{_max_parallelism},
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'removeinputs!' => \$self->{_remove_inputs},
	'test=s' => \$self->{_test},
	'T|tmpdir|tempdir=s' => \$self->{_tmpdir},
	'xargs!' => \$self->{_xargs},
	# sort key options:
	'n|numeric' => sub { $self->parse_sort_option(@_); },
	'N|lexical' => sub { $self->parse_sort_option(@_); },
	'r|descending' => sub { $self->parse_sort_option(@_); },
	'R|ascending' => sub { $self->parse_sort_option(@_); },
	'<>' => sub { if ($past_sort_options) {
			    $self->parse_io_option('inputs', @_);
			} else  {
			    $self->parse_sort_option('<>', @_);
			};
		    },
	) or pod2usage(2);
}

=head2 _pretty_fn

    _pretty_fn($fn)

Internal: pretty-print a filename or Fsdb::BoundedQueue.

=cut

sub _pretty_fn {
    my($fn) = @_;
    return ref($fn) if (ref($fn));
    return $fn;
}


=head2 segment_next_output

    $out = $self->segment_next_output($output_type)

Internal: return a Fsdb::IO::Writer as $OUT
that either points to our output or a temporary file, 
depending on how things are going.

The $OUTPUT_TYPE can be 'final' or 'ipc' or 'file'.

=cut

sub segment_next_output($$) {
    my ($self, $output_type) = @_;
    my $out;
    if ($output_type eq 'final') {
#        $self->finish_io_option('output', -clone => $self->{_two_ins}[0]);
#        $out = $self->{_out};
	$out = $self->{_output};   # will pass this to the dbmerge2 module
	print "# final output\n" if ($self->{_debug});
    } elsif ($output_type eq 'file') {
	# dump to a file for merging
	my $tmpfile = Fsdb::Support::NamedTmpfile::alloc($self->{_tmpdir});
	$self->{_files_cleanup}{$tmpfile} = 'NamedTmpfile';
	$out = $tmpfile;   # just return the name
    } elsif ($output_type eq 'ipc') {
	# endgame-mode: send stuff down in-memory queues
	# $out = shared_clone(new Fsdb::BoundedQueue);
	my $read_fh = new IO::Handle;
	my $write_fh = new IO::Handle;
	pipe $read_fh, $write_fh;
	# Without these lines we suffer mojobake on unicode
	# as shown in test base TEST/dbsort_merge_unicode.cmd.
        binmode $read_fh, ":utf8";
        binmode $write_fh, ":utf8";
	$out = [ $read_fh, $write_fh ];
    } else {
	croak("internal error: dbmege.pm:segment_next_output bad output_type: $output_type\n");
    };
    return $out;
}


=head2 segment_cleanup

    $out = $self->segment_cleanup($file);

Internal: Clean up a file, if necessary.
(Sigh, used to be function pointers, but 
not clear how they would interact with threads.)

=cut

sub segment_cleanup($$) {
    my($self, $file) = @_;
    if (ref($file)) {
	if (ref($file) =~ /^IO::/) {
	    print "# closing IO::*\n" if ($self->{_debug});
	    $file->close;
	} elsif (ref($file) eq 'Fsdb::BoundedQueue') {
	    # nothing to do
	} else {
	    croak("internal error: unknown type in dbmerge::segment_cleanup\n");
	};
	return;
    };
    my($cleanup_type) = $self->{_files_cleanup}{$file};
    croak("bad (empty) file in dbmerge::segment_cleanup\n")
	if (!defined($file));
    if (!defined($cleanup_type)) {
	print "# dbmerge: segment_cleanup:  no cleanup for " . _pretty_fn($file) . "\n" if ($self->{_debug});
	# nothing
    } elsif ($cleanup_type eq 'unlink') {
	print "# dbmerge: segment_cleanup: cleaning up $file\n" if ($self->{_debug});
	unlink($file);
    } elsif ($cleanup_type eq 'NamedTmpfile') {
	print "# dbmerge: segment_cleanup:  NamedTmpfile::cleanup_one $file\n" if ($self->{_debug});
	Fsdb::Support::NamedTmpfile::cleanup_one($file);
    } else {
	croak($self->{_prog} . ": internal error, unknown segment_cleanup type $cleanup_type\n");
    };
}

=head2 _unique_id

    $id = $self->_unique_id()

Generate a sequence number for debugging.

=cut
sub _unique_id() {
    my($self) = @_;
    $self->{_unique_id} //= 0;
    return $self->{_unique_id}++;
};


=head2 segments_merge2_run

    $out = $self->segments_merge2_run($out_fn, $is_final_output, 
			$in0, $in1, $id);


Internal: do the actual merge2 work (maybe our parent put us in a
thread, maybe not).

=cut
sub segments_merge2_run($$$$$$) {
    my($self, $out_fn, $is_final_output, $in0, $in1, $id) = @_;

    my @merge_options = qw(--autorun --nolog);
    push(@merge_options, '--noclose', '--saveoutput' => \$self->{_out})
	if ($is_final_output);
    push(@merge_options, '--header' => $self->{_header})
	if ($self->{_header});

    my $debug_msg = '';
    if ($self->{_debug}) {
	$debug_msg = "(id $id) " . _pretty_fn($in0) . " with " . _pretty_fn($in1) . " to " . _pretty_fn($out_fn) . " " . ($is_final_output ? " (final)" : "") . " " . join(" ", @merge_options);
    };
    print "# segments_merge2_run: merge start $debug_msg\n"
	if ($self->{_debug});
    new Fsdb::Filter::dbmerge2(@merge_options,
			'--input' => $in0,
			'--input' => $in1,
			'--output' => $out_fn,
			@{$self->{_sort_argv}});
    print "# segments_merge2_run: merge finish $debug_msg\n"
	if ($self->{_debug});

    $self->segment_cleanup($in0);
    $self->segment_cleanup($in1);
    if (!$is_final_output) {
        print "# segments_merge2_run: merge closing out " . ref($out_fn) . " $debug_msg\n"
	    if ($self->{_debug});
    };
}

=head2 segments_merge1_run

    $out = $self->segments_merge1_run($out_fn, $in0);

Internal: a special case of merge1 when we have only one file.

=cut
sub segments_merge1_run($$$) {
    my($self, $out_fn, $in0) = @_;

    my @col_options = qw(--all --autorun --nolog);
    push(@col_options, '--noclose', '--saveoutput' => \$self->{_out});  # $is_final_output
    push(@col_options, '--header' => $self->{_header})
	if ($self->{_header});

    my $debug_msg = '';
    if ($self->{_debug}) {
	$debug_msg = _pretty_fn($in0) . " to " . _pretty_fn($out_fn) . " (final) " . join(" ", @col_options);
    };
    print "# segments_merge1_run: merge start $debug_msg\n"
	if ($self->{_debug});
    new Fsdb::Filter::dbcol(@col_options,
			'--input' => $in0,
                            '--output' => $out_fn);
    print "# segments_merge1_run: merge finish $debug_msg\n"
	if ($self->{_debug});

    $self->segment_cleanup($in0);
    print "# segments_merge1_run: merge closing out " . ref($out_fn) . " $debug_msg\n"
        if ($self->{_debug});
}


=head2 enqueue_work

    $self->enqueue_work($depth, $work);

Internal: put $WORK on the queue at $DEPTH, updating the max count.

=cut

sub enqueue_work($$$) {
    my($self, $depth, $work) = @_;
    $self->{_work_max_files}[$depth] //= 0;
    $self->{_work_max_files}[$depth]++;
    push(@{$self->{_work}[$depth]}, $work);
};

=head2 segments_merge_one_depth

    $self->segments_merge_one_depth($depth);

Merge queued files, if any.

Also release any queued threads.

=cut

sub segments_merge_one_depth($$) {
    my($self, $depth) = @_;

    my $work_depth_ref = $self->{_work}[$depth];
    return if ($#$work_depth_ref == -1);   # no work at this dpeth for now

    my $closed = $self->{_work_closed}[$depth];

    print "# segments_merge_one_depth: scanning $depth\n" if ($self->{_debug});
    #
    # Merge the files in a binary tree.
    #
    # In the past, we did this in a very clever
    # a file-system-cache-friendly order, based on ideas from
    # "Information and Control in Gray-box Systems" by
    # the Arpaci-Dusseaus at SOSP 2001.
    #
    # Unfortunately, this optimization makes the sort unstable
    # and complicated,
    # so it was dropped when paralleism was added.
    #
    while ($#{$work_depth_ref} >= ($closed ? 0 : 3)) {
	if ($#{$work_depth_ref} == 0) {
	    last if (!$closed);
	    # one left, just punt it next
	    print "# segments_merge_one_depth: runt at depth $depth pushed to next depth.\n" if ($self->{_debug});
	    $self->enqueue_work($depth + 1, shift @{$work_depth_ref});
	    croak("internal error\n") if ($#{$work_depth_ref} != -1);
	    last;
	};
	# are they blocked?  force-start them if they are
	my $waiting_on_inputs = 0;
	foreach my $i (0..1) {
	    my $work_ref = $work_depth_ref->[$i];
	    if ($work_ref->[0] == -1) {
		print "# segments_merge_one_depth: depth $depth forced start on $work_ref->[1].\n" if ($self->{_debug});
		&{$work_ref->[2]}($work_ref);  # start it
		$waiting_on_inputs++;
	    } elsif ($work_ref->[0] == 0) {
		print "# segments_merge_one_depth: depth $depth waiting on working " . _pretty_fn($work_ref->[1]) . ".\n" if ($self->{_debug});
		$waiting_on_inputs++;
	    } elsif ($work_ref->[0] == 1) {
		# running, so move fred to zombie queue; otherwise ok
		print "# segments_merge_one_depth: pushing job to zombie list.\n" if ($self->{_debug});
		push(@{$self->{_zombie_work}}, $work_ref);
	    } elsif ($work_ref->[0] == 2) {
		# input is done
	    } else {
		croak("interal error: unknown status $work_ref->[0]\n");
	    };
	};
	# bail out if inputs are not done yet.
	return if ($waiting_on_inputs);

	# now we KNOW we do not have blocked work
	my(@two_fn) = (shift @${work_depth_ref}, shift @${work_depth_ref});
	my $output_type = 'file';
	if ($closed && $#{$work_depth_ref} == -1 && $depth == $#{$self->{_work}}) {
	    $output_type = 'final';
	} elsif ($self->{_endgame} && $closed && $self->{_work_max_files}[$depth] <= $self->{_endgame_max_files}) {
	    print "# segments_merge_one_depth: endgame parallelism.\n" if ($self->{_debug});
	    $output_type = 'ipc';
	};
	my($out_fn) = $self->segment_next_output($output_type);
	print "# segments_merge_one_depth: depth $depth planning " . _pretty_fn($two_fn[0][1]) . " and " . _pretty_fn($two_fn[1][1]) . " to " . _pretty_fn($out_fn) . ".\n" if ($self->{_debug});

	foreach my $i (0..1) {
	    next if (ref($two_fn[$i][1]) =~ /^(Fsdb::BoundedQueue|IO::)/ || $two_fn[$i][1] eq '-');
	    croak($self->{_prog} . ": file $two_fn[$i][1] is missing.\n")
		if (! -f $two_fn[$i][1]);
	};

	if ($output_type eq 'final') {
		# last time: do it here, in-line
		# so that we update $self->{_out} in the main thread
		$self->segments_merge2_run($out_fn, 1, $two_fn[0][1], $two_fn[1][1], $self->_unique_id());
		return;
	};
	#
	# fork a Fred to do the merge
	#
	my $out_fn_reader = (ref($out_fn) eq 'ARRAY') ? $out_fn->[0] : $out_fn;
	my $out_fn_writer = (ref($out_fn) eq 'ARRAY') ? $out_fn->[1] : $out_fn;
	$out_fn = undef;
	my $new_work_ref = [-1, $out_fn_reader, undef];
	my $unique_id = $self->_unique_id();
	my $desc = "dbmerge2($two_fn[0][1],$two_fn[1][1]) => $out_fn_reader (id $unique_id)";
	my $start_sub = sub {
		$self->{_parallelism_available}--;
		$new_work_ref->[0] = ($output_type eq 'ipc' ? 1 : 0);   # running
		my $fred = new Fsdb::Support::Freds($desc, sub {
			$out_fn_reader->close if ($output_type eq 'ipc');
			print "# segments_merge_one_depth: Fred start $desc\n" if ($self->{_debug});
			$self->segments_merge2_run($out_fn_writer, 0, $two_fn[0][1], $two_fn[1][1], $unique_id);
			sleep(1) if (defined($self->{_test}) && $self->{_test} eq 'delay-finish');
			print "# segments_merge_one_depth: Fred end $desc\n" if ($self->{_debug});
			exit 0;
		    }, sub {
			my($done_fred, $exit_code) = @_;
			# we're done!
			print "# segments_merge_one_depth: Fred post-mortem $desc\n" if ($self->{_debug});
			# xxx: with TEST/dbmerge_3_input.cmd I sometimes get exit code 255 (!) although things complete. 
			# turned out Fsdb::Support::Freds::END was messing with $?.
			croak("dbmerge: merge2 subprocess $desc, exit code: $exit_code\n") if ($exit_code != 0);
			$new_work_ref->[0] = 2;  # done
		    });
		$new_work_ref->[2] = $fred;
		$out_fn_writer->close if ($output_type eq 'ipc');  # discard
	    };
	$new_work_ref->[2] = $start_sub;
	# Put the thread in our queue,
	# and run it if it's important (pipe or final),
	# or if we have the capacity.
 	$self->enqueue_work($depth + 1, $new_work_ref);
	&$start_sub() if ($output_type ne 'file' || $self->{_parallelism_available} > 0);
	print "# segments_merge_one_depth: looping after $desc.\n" if ($self->{_debug});
    };
    # At this point all possible work has been queued and maybe started.
    # If the depth is closed, the work should be empty.
    # if not, there may be some files in the queue
}

=head2 segments_xargs

    $self->segments_xargs();

Internal: read new filenames to process (from stdin)
and send them to the work queue.

Making a separate Fred to handle xargs is a lot of work, 
but it guarantees it comes in on an IO::Handle that is selectable.

=cut

sub segments_xargs($) {
    my($self) = @_;
    my $ipc = $self->{_xargs_ipc_writer};

    my $num_inputs = 0;

    # read files as in fsdb format
    if ($#{$self->{_inputs}} == 0) {
	# hacky...
	$self->{_input} = $self->{_inputs}[0];
    };
    $self->finish_io_option('input', -header => '#fsdb filename', -comment_handler => undef);
    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    while (my $fref = &$read_fastpath_sub()) {
        next if (!defined($fref) || $#$fref != 0);   # handle zero files
	# send each file for processing as level zero
	print "# dbmerge: segments_xargs: got $fref->[0]\n" if ($self->{_debug});
	$ipc->print($fref->[0] . "\n");
	$num_inputs++;
    };
    # We need to catch 0 or 1 input file in the xargs reader.
#    if ($num_inputs == 0) {
#	$ipc->print("-1\terror: --xargs, but zero or one input files; dbmerge needs at least two.\n");  # signal eof-f
#    };
    $ipc->close;
    $self->{_ipc_writer} = undef;
}


=head2 segments_merge_all

    $self->segments_merge_all()

Internal:
Merge queued files, if any.
Iterates over all depths of the merge tree,
and handles any forked threads.

=head3 Merging Strategy

Merging is done in a binary tree is managed through the C<_work> queue.
It has an array of C<depth> entries,
one for each level of the tree.

Items are processed in order at each level of the tree,
and only level-by-level, so the sort is stable.

=head3 Parallelism Model

Parallelism is also managed through the C<_work> queue,
each element of which consists of one file or stream suitable for merging.
The work queue contains both ready output (files or BoundedQueue streams)
that can be immediately handled, and pairs of semaphore/pending output
for work that is not yet started.
All manipulation of the work queue happens in the main thread
(with C<segments_merge_all> and C<segments_merge_one_depth>).

We start a thread to handle each item in the work queue,
and limit parallelism to the C<_max_parallelism>,
defaulting to the number of available processors.

There two two kinds of parallelism, regular and endgame.
For regular parallelism we pick two items off the work queue,
merge them, and put the result back on the queue as a new file.
Items in the work queue may not be ready.  For in-progress items we
wait until they are done.  For not-yet-started items
we start them, then wait until they are done.

Endgame parallelism handles the final stages of a large merge.
When there are enough processors that we can start a merge jobs
for all remaining levels of the merge tree.  At this point we switch
from merging to files to merging into C<Fsdb::BoundedQueue> pipelines
that connect merge processes which start and run concurrently.

The final merge is done in the main thread so that that the main thread
can handle the output stream and recording the merge action.

=cut

sub segments_merge_all($) {
    my($self) = @_;

    my $xargs_select;
    if ($self->{_xargs}) {
	$xargs_select = IO::Select->new();
	$xargs_select->add($self->{_xargs_ipc_reader});
    };

    #
    # Alternate forking off new merges from finished files
    # and reaping finished processes.
    #
    my $overall_progress = 0;
    my $overall_progress_last_reset = 0;
    my $PROGRESS_START = 0.001;
    my $PROGRESS_MAX = 2;
    my $PROGRESS_MULTIPLIER = 2;
    my $progress_backoff = $PROGRESS_START;
    for (;;) {
	# done?
	my $deepest = $#{$self->{_work}};
	if ($self->{_work_closed}[$deepest] && $#{$self->{_work}[$deepest]} <= 0) {
            if ($deepest == 0 && $#{$self->{_work}[$deepest]} == 0) {
                # special case singleton file (must be from xargs)
                print "# segments_merge_all: singleton file from xargs\n" if ($self->{_debug});
                # handle it here, in-line, so we update $self->{_out}
                my($out_fn) = $self->segment_next_output('final');
                my($in0) = $self->{_work}[$deepest][0][1];
		$self->segments_merge1_run($out_fn, $in0);
            } elsif ($deepest == 0 && $#{$self->{_work}[$deepest]} == -1) {
                # special case: xargs and no files.
                croak($self->{_prog} . ": xargs, but no files for input\n")
                    if ($self->{_xargs});
            };
            # all done for real
            last;
        };

	#
	# First, put more work on the queue, where possible.
	#
	# Go through this loop multiple times because closing the last depth
	# can actually allow work to start at the last+1 depth,
	# and in endgame mode we risk blocking (due to flow control)
	# if we don't start threads at all depths.
	#
	my $try_again = 1;
	while ($try_again) {
	    foreach my $depth (0..$#{$self->{_work}}) {
	        $self->segments_merge_one_depth($depth);
		$try_again = undef;
	        if ($#{$self->{_work}[$depth]} == -1 && $self->{_work_closed}[$depth]) {
		    # When one level is all in progress, we can close the next.
		    my $next_depth = $depth + 1;
		    if (!$self->{_work_closed}[$next_depth]) {
		        $self->{_work_closed}[$next_depth] = 1;
			$try_again = 1;
			$overall_progress++;
		        print "# segments_merge_all: closed work depth $next_depth\n" if ($self->{_debug});
		    };
		};
	    };
	};

	#
	# Next, handle Freds that have finished.
	# Reap as many as possible.
	#
	print "# segments_merge_all: reaping threads\n" if ($self->{_debug});
	for (;;) {
	    my $fred_or_code = Fsdb::Support::Freds::join_any();
	    last if (ref($fred_or_code) eq '');
	    $overall_progress++;
	    croak("dbmerge: merge thread failed\n")
		if ($fred_or_code->exit_code() != 0);
	    print "# segments_merge_all: merged fred " . $fred_or_code->info() . "\n" if ($self->{_debug});
	};

	#
	# Now start up more parallelism, if possible.
	#
	my $depth = 0;
	my $i = 0;
	while ($self->{_parallelism_available} > 0) {
	    my $work_ref = $self->{_work}[$depth][$i];
	    if (defined($work_ref) && $work_ref->[0] == -1) {
		# start it (it will decrement parallelism)
		&{$work_ref->[2]}($work_ref);
		$overall_progress++;
	    };
	    # walk the whole work queue
	    if (++$i > $#{$self->{_work}[$depth]}) {
		last if (++$depth > $#{$self->{_work}});
		$i = 0;
	    };
	};

	#
	# Handle xargs, if any.
	#
	# Unfortunately, we busy-loop here,
	# because we need to alternate reaping finished processes
	# and xargs.
	#
	# Fortunately, this terminates when xargs are complete.
       	#
	if ($self->{_xargs_ipc_status}) {
	    my(@ready) = $xargs_select->can_read($progress_backoff);
	    foreach my $fh (@ready) {
		my ($fn) = $fh->getline;
		if (defined($fn)) {
		    chomp($fn);
                    $self->{_files_cleanup}{$fn} = 'unlink'
                        if ($self->{_remove_inputs});
                    $self->enqueue_work(0, [2, $fn, undef]);
                    $self->{_xargs_ipc_count}++;
                    print "# xargs receive $fn, file " . $self->{_xargs_ipc_count} . "\n" if ($self->{_debug});
		} else {
		    # eof, so no more xargs
		    $self->{_work_closed}[0] = 1;
                    # We could check for special cases of 0 or 1 file.
                    # But we don't.  Just pass them through to the parent who will handle it.
                    # if ($self->{_xargs_ipc_count} == 0) {
                    #	croak($self->{_prog} . ": xargs, but no files for input\n");
                    # } elsif ($self->{_xargs_ipc_count} == 1) {
                    	# carp($self->{_prog} . ": xargs, but one file for input\n");
                        # Pass through and we will catch this case
                        # in the main segements_merge_all loop.
                    # };
		};
		$overall_progress++;
            };
	};
	#
	# Avoid spinlooping.
	#
	if ($overall_progress <= $overall_progress_last_reset) {
	    # No progress, so stall.
	    print "# segments_merge_all: stalling for $progress_backoff\n" if ($self->{_debug});
	    sleep($progress_backoff);
	    $progress_backoff *= $PROGRESS_MULTIPLIER;  # exponential backoff
	    $progress_backoff = $PROGRESS_MAX if ($progress_backoff > $PROGRESS_MAX);
	} else {
	    # Woo-hoo, did something.  Rush right back and try again.
	    $overall_progress_last_reset = $overall_progress;
	    $progress_backoff = $PROGRESS_START;
	};
    };

    # reap endgame zombies
    while (my $zombie_work_ref = shift(@{$self->{_zombie_work}})) {
	next if ($zombie_work_ref->[0] == 2);
	print "# waiting on zombie " . $zombie_work_ref->[2]->info() . "\n" if ($self->{_debug});
	$zombie_work_ref->[2]->join();
	croak("internal error: zombie didn't reset status\n") if ($zombie_work_ref->[0] != 2);
    };

    # reap xargs (if it didn't already get picked up)
    if ($self->{_xargs_fred}) {
	print "# waiting on xargs fred\n" if ($self->{_debug});
	$self->{_xargs_fred}->join();
    };
    # 
}



=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup($) {
    my($self) = @_;

    croak($self->{_prog} . ": no sorting key specified.\n")
	if ($#{$self->{_sort_argv}} == -1);

    if (!$self->{_xargs} && $#{$self->{_inputs}} == -1) {
	croak($self->{_prog} . ": no input sources specified, use --input or --xargs.\n");
    };
    if (!$self->{_xargs} && $#{$self->{_inputs}} == 0) {
	croak($self->{_prog} . ": only one input source, but can't merge one file.\n");
    };
    if ($self->{_xargs} && $#{$self->{_inputs}} > 0) {
	croak($self->{_prog} . ": --xargs and multiple inputs (perhaps you meant NOT --xargs?).\n");
    };
    # prove files exist (early error checking)
    foreach (@{$self->{_inputs}}) {
	next if (ref($_) ne '');   # skip objects
	next if ($_ eq '-');   # special case: stdin
	if (! -f $_) {
	    croak($self->{_prog} . ": input source $_ does not exist.\n");
	};
    };
    if ($self->{_remove_inputs}) {
	foreach (@{$self->{_inputs}}) {
	    $self->{_files_cleanup}{$_} = 'unlink'
		if ($_ ne '-');
	};
    };
    #
    # the _work queue consists of
    # 1. [2, filenames, fred] that for completed files need to be merged.
    # 1a. [1, IO::Handle::Pipe, fred] for files that are being processed
    #	    and can be merged (but are not yet done).
    # 2. [-1, filename, $start_sub] for blocked threads that, when started
    #       by evaling $start_sub, will go to filename.
    # 3. [0, filename, fred] for files in the process of being computed
    #
    # Filename can be an Fsdb::BoundedQueue or IO::Pipe objects for endgame mode threads
    #
    # _work_closed is set when that depth is no longer growing;
    # at that time _work_depth_files is the maximum number of files there.
    #
    # Put stuff on it with $self->enqueue_work to keep the 
    # related variables correct.
    #
    $self->{_work}[0] = [];
    $self->{_work_closed}[0] = 0;
    $self->{_work_depth_files}[0] = 0;
    $self->{_xargs_ipc_status} = undef;
    $self->{_zombie_work} = [];   # collect in-process but not-yet-done freds
    if (!$self->{_xargs}) {
	foreach (@{$self->{_inputs}}) {
	    $self->enqueue_work(0, [2, $_, undef]);
	};
	$self->{_work_closed}[0] = 1;
    } else {
        my $xargs_ipc_reader = new IO::Handle;
	my $xargs_ipc_writer = new IO::Handle;
	pipe($xargs_ipc_reader, $xargs_ipc_writer) or croak("cannot open pipe\n");
	$self->{_xargs_ipc_status} = 'running';
	$self->{_xargs_ipc_count} = 0;
	$self->{_xargs_fred} = new Fsdb::Support::Freds('dbmerge:xargs',
	    sub {
		$SIG{PIPE} = 'IGNORE';   # in case we finish before main reads anything
		$xargs_ipc_reader->close;
	    	$xargs_ipc_writer->autoflush(1);
		$self->{_xargs_ipc_writer} = $xargs_ipc_writer;
		$self->segments_xargs();
		exit 0;
	    }, sub {
	    	$self->{_xargs_ipc_status} = 'completed';
	    });
	$xargs_ipc_reader->autoflush(1);
	$xargs_ipc_writer->close;
	$self->{_xargs_ipc_reader} = $xargs_ipc_reader;
	# actual xargs reception happens in our main loop in segments_merge_all()
    };
    #
    # control parallelism
    #
    # For the endgame, we overcommit by a large factor
    # because in the merge tree many become blocked on the IO pipeline.
    #
    $self->{_max_parallelism} //= Fsdb::Support::OS::max_parallelism();
    $self->{_parallelism_available} //= $self->{_max_parallelism};
    my $viable_endgame_processes = $self->{_max_parallelism};
    my $files_to_merge = 1;
    while ($viable_endgame_processes > 0) {
	$viable_endgame_processes -= $files_to_merge;
	$files_to_merge *= 2;
    };
    $self->{_endgame_max_files} = int($files_to_merge);
    STDOUT->autoflush(1) if ($self->{_debug});
    print "# dbmerge: endgame_max_files: " . $self->{_endgame_max_files} . "\n" if($self->{_debug});
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run($) {
    my($self) = @_;

    $self->segments_merge_all();
};

    

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2020 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
