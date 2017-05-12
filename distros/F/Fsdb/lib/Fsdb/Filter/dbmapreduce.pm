#!/usr/bin/perl -w

#
# dbmapreduce.pm
# Copyright (C) 1991-2016 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#


package Fsdb::Filter::dbmapreduce;

=head1 NAME

dbmapreduce - reduce all input rows with the same key

=head1 SYNOPSIS

    dbmapreduce [-dMS] [-k KeyField] [-f CodeFile] [-C Filtercode] [--] [ReduceCommand [ReduceArguments...]]

=head1 DESCRIPTION

Group input data by KeyField,
then apply a function (the "reducer") to each group.
The reduce function can be an external program
given by ReduceCommand and ReduceArguments,
or an Perl subroutine given in CodeFile or FilterCode.

If a "--" appears before reduce command,
arguments after the -- passed the the command.


=head2 Grouping (The Mapper)

By default the KeyField is the first field in the row.
Unlike Hadoop streaming, the -k KeyField option can explicitly
name where the key is in any column of each input row.

By default, we sort the data to make sure data is grouped by key.
If the input is already grouped, the C<-S> option avoids this cost.


=head2 The Reducer

Reduce functions default to be shell commands.
However, with C<-C>, one can use arbitrary Perl code

(see the C<-C> option below for details).
the C<-f> option is useful to specify complex Perl code
somewhere other than the command line.

Finally, as a special case, if there are no rows of input,
the reducer will be invoked once with the empty value (if it's an external 
reducer) or with undef (if it's a subroutine).
It is expected to generate the output header,
and it may generate no data rows itself, or a null data row
of its choosing.

=head2 Output

For non-multi-key-aware reducers,
we add the KeyField use for each Reduce
is in the output stream.
(If the reducer passes the key we trust that it gives a correct value.)
We also insure that the output field separator is the
same as the input field separator.

Adding the key and adjusting the output field separator
is not possible for 
non-multi-key-aware reducers.


=head2 Comparison to Related Work

This program thus implements Google-style map/reduce,
but executed sequentially.

For input, these systems include a map function and apply it to input data
to generate the key.
We assume this key generation (the map function)
has occurred head of time.

We also allow the grouping key to be in any column.  
Hadoop Streaming requires it to be in the first column.

By default, the reducer gets exactly (and only) one key.
This invariant is stronger than Google and Hadoop.
They both pass multiple keys to the
reducer, insuring that each key is grouped together.
With the C<-M> option, we also pass multiple multiple groups to the reducer.

Unlike those systems, with the C<-S> option
we do not require the groups arrive in any particular
order, just that they be grouped together.
(They guarantees they arrive in lexically sorted order).
However, with C<-S> we create lexical ordering.

With C<--prepend-key> we insure that the KeyField is in the output stream;
other systems do not enforce this.


=head2 Assumptions and requirements

By default, data can be provided in arbitrary order
and the program consumes O(number of unique tags) memory,
and O(size of data) disk space.

With the C<-S> option, data must arrive group by tags (not necessarily sorted),
and the program consumes O(number of tags) memory and no disk space.
The program will check and abort if this precondition is not met.

With two C<-S>'s, program consumes O(1) memory, but doesn't verify
that the data-arrival precondition is met.

The field separators of the input and the output
can now be different
(early versions of this tool prohibited such variation.)
With C<--copy-fs> we copy the input field separator to the output,
but only for non-multi-key-aware reducers.
(this used to be done automatically).


=head2 Known bugs

As of 2013-09-21, we don't verify key order with options C<-M -S>.


=head1 OPTIONS

=over 4

=item B<-k> or B<--key> KeyField

specify which column is the key for grouping (default: the first column)

=item B<-S> or B<--pre-sorted>

Assume data is already grouped by tag.
Provided twice, it removes the validation of this assertion.

=item B<-M> or B<--multiple-ok>

Assume the ReduceCommand can handle multiple grouped keys,
and the ReduceCommand is responsible for outputting the  
with each output row.
(By default, a separate ReduceCommand is run for each key,
and dbmapreduce adds the key to each output row.)

=item B<-K> or B<--pass-current-key>

Pass the current key as an argument to the external,
non-map-aware ReduceCommand.
This is only done optionally since some external commands 
do not expect an extra argument.
(Internal, non-map-aware Perl reducers are always given 
the current key as an argument.)

=item B<--prepend-key>

Add the current key into the reducer output
for non-multi-key-aware reducers only.
Not done by default.

=item B<--copy-fs> or B<--copy-fieldseparator>

Change the field separator of a
non-multi-key-aware reducers to match the input's field separator.
Not done by default.

=item B<--parallelism=N> or B<-j N>

Allow up to N reducers to run in parallel.
Default is the number of CPUs in the machine.

=item B<-C FILTER-CODE> or B<--filter-code=FILTER-CODE>

Provide FILTER-CODE, Perl code that generates and returns
a Fsdb::Filter object that implements the reduce function.
The provided code should be an anonymous sub
that creates a Fsdb Filter that implements the reduce object.

The reduce object will then be called with --input and --output
parameters that hook it into a the reduce with queues.

One sample fragment that works is just:

    dbcolstats(qw(--nolog duration))

So this command:

    cat DATA/stats.fsdb | \
	dbmapreduce -k experiment -C 'dbcolstats(qw(--nolog duration))'

is the same as the example

    cat DATA/stats.fsdb | \
	dbmapreduce -k experiment -- dbcolstats duration

except that with C<-C> there is no forking and so things run faster.

If C<dbmapreduce> is invoked from within Perl, then one can use
a code SUB as well:
    dbmapreduce(-k => 'experiment', 
	-C => sub { dbcolstats(qw(--nolong duration)) }); 

The reduce object must consume I<all> input as a Fsdb stream,
and close the output Fsdb stream.  (If this assumption is not
met the map/reduce will be aborted.)

For non-map-reduce-aware filters,
when the filter-generator code runs, C<$_[0]> will be the current key.

=item B<-f CODE-FILE> or B<--code-file=CODE-FILE>

Includes F<CODE-FILE> in the program.
This option is useful for more complicated perl reducer functions.

Thus, if reducer.pl has the code.

    sub make_reducer {
	my($current_key) = @_;
	dbcolstats(qw(--nolog duration));
    }

Then the command

    cat DATA/stats.fsdb | \
	dbmapreduce -k experiment -f reducer.pl -C make_reducer

does the same thing as the example.


=item B<-w> or B<--warnings>

Enable warnings in user supplied code.
Warnings are issued if an external reducer fails to consume all input.
(Default to include warnings.)

=item B<-T TmpDir>

where to put tmp files.
Also uses environment variable TMPDIR, if -T is 
not specified.
Default is /tmp.

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

    #fsdb experiment duration
    ufs_mab_sys 37.2
    ufs_mab_sys 37.3
    ufs_rcp_real 264.5
    ufs_rcp_real 277.9

=head2 Command:

    cat DATA/stats.fsdb | \
	dbmapreduce --prepend-key -k experiment -- dbcolstats duration

=head2 Output:

    #fsdb      experiment      mean    stddev  pct_rsd conf_range      conf_low       conf_high        conf_pct        sum     sum_squared     min     max     n
    ufs_mab_sys     37.25 0.070711 0.18983 0.6353 36.615 37.885 0.95 74.5 2775.1 37.2 37.3 2
    ufs_rcp_real    271.2 9.4752 3.4938 85.13 186.07 356.33 0.95 542.4 1.4719e+05 264.5 277.9 2
    #  | dbmapreduce -k experiment dbstats duration


=head1 SEE ALSO

L<Fsdb>.
L<dbmultistats>
L<dbrowsplituniq>


=head1 CLASS FUNCTIONS

OLD TEXT:
A few notes about the internal structure:
L<dbmapreduce> uses two to four threads (actually Freds) to run.
An optional thread C<$self->{_in_fred}> sorts the input.
The main process reads input and groups input by key.
Each group is passed to a
secondary fred C<$self->{_reducer_thread}>
that invokes the reducer on each group
and does any output.
If the reducer is I<not> map-aware, then
we create a final postprocessor thread that 
adds the key back to the output.
Either the reducer or the postprocessor thread do output.

NEW VERSION with Freds:

A few notes about parallelism, since we have fairly different structure
depending on what we're doing:

1. for multi-key aware reducers, there is no output post-processing.

1a. if input is sorted and there is no input checking (-S -S),
we run the reducer in our own process.
(F<TEST/dbmapreduce_multiple_aware_sub.cmd>)

1b. with grouped input and input checking (-S), 
we fork off an input process that checks grouping,
then run the reducer in our process.
(F<TEST/dbmapreduce_multiple_aware_sub_checked.cmd>)
xxx: case 1b not yet done

1c. with ungrouped input,
we invoke an input process to do sorting,
then run the reducer in our process.
(F<TEST/dbmapreduce_multiple_aware_sub_ungrouped.cmd>)

2. for non-multi-key aware.
A sorter thread groups content, if necessary.
We breaks stuff into groups
and feeds them to a reducer Fred, one per group.
A dedicated additional Fred merges output and addes the missing key,
if necessary.
Either way, output ends up in a file.
A finally postprocessor thread merges all the output files.

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use 5.010;
use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;
use Fsdb::Filter::dbsubprocess;
use Fsdb::Support::NamedTmpfile;
use Fsdb::Support::OS;
use Fsdb::Filter::dbpipeline qw(dbpipeline_filter dbpipeline_sink dbsort dbcolcreate dbfilecat dbfilealter dbsubprocess);

my $REDUCER_GROUP_SYNCHRONIZATION_FLAG = 'reducer group synchronization flag';

=head2 new

    $filter = new Fsdb::Filter::dbmapreduce(@arguments);

Create a new dbmapreduce object, taking command-line arguments.

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
    $self->{_key_column} = undef;
    $self->{_pre_sorted} = 0;
    $self->{_filter_generator_code} = undef;
    $self->{_reduce_generator} = undef;
    $self->{_reducer_is_multikey_aware} = undef;
    $self->{_external_command_argv} = [];
    $self->{_pass_current_key} = undef;
    $self->{_prepend_key} = undef;
    $self->{_copy_fscode} = undef;
    $self->{_filter_generator_code} = undef;
    $self->{_code_files} = [];
    $self->{_warnings} = 1;
    $self->{_max_parallelism} = undef;
    $self->{_parallelism_available} = undef;
    $self->{_test_parallelism} = undef;
    $self->{_header} = undef;
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
	'autorun!' => \$self->{_autorun},
	'C|filter-code|code=s' => \$self->{_filter_generator_code},
	'close!' => \$self->{_close},
	'copy-fs|copy-fieldseparator!' => \$self->{_copy_fscode},
	'd|debug+' => \$self->{_debug},
	'f|code-files=s@' => $self->{_code_files},
	'header=s' => \$self->{_header},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'j|parallelism=i' => \$self->{_max_parallelism},
	'k|key=s' => \$self->{_key_column},
	'K|pass-current-key!' => \$self->{_pass_current_key},
	'prepend-key' => sub { $self->{_prepend_key} = 1; },
	'no-prepend-key' => sub { $self->{_prepend_key} = 0; }, # set but false
	'log!' => \$self->{_logprog},
	'M|multiple-ok!' => \$self->{_reducer_is_multikey_aware},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'S|pre-sorted+' => \$self->{_pre_sorted},
	'test-parallelism!' => \$self->{_test_parallelism},  # for test suite only
	'T|tmpdir|tempdir=s' => \$self->{_tmpdir},
	'saveoutput=s' => \$self->{_save_output},
        'w|warnings!' => \$self->{_warnings},
	) or pod2usage(2);
    push (@{$self->{_external_command_argv}}, @argv);
}


=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup($) {
    my($self) = @_;

    $self->{_prepend_key} = !$self->{_reducer_is_multikey_aware}
	if (!defined($self->{_prepend_key}));
    croak $self->{_prog} . ": cannot prepend keys for multikey-aware reducers.\n"
	if ($self->{_prepend_key} && $self->{_reducer_is_multikey_aware});

    my $included_code = '';
    #
    # get any extra code
    #
    foreach my $code_file (@{$self->{_code_files}}) {
	open(IN, "< $code_file") or croak $self->{_prog} . ": cannot read code from $code_file\n";
	$included_code .= join('', <IN>);
	close IN;
    };

    #
    # control parallelism
    #
    $self->{_max_parallelism} //= Fsdb::Support::OS::max_parallelism();
    $self->{_max_parallelism} = 1 if ($self->{_max_parallelism} < 1);  # always allow some
    $self->{_parallelism_available} //= $self->{_max_parallelism};

    #
    # what are we running?
    #
    # Figure it out, and generate a 
    # $self->{_reducer_generator_sub} that creates a
    # filter object that will be passed to dbpipeline_open2
    # to reduce one (or many, if map_aware_reducer) keys.
    #
    if ($#{$self->{_external_command_argv}} >= 0) {
	# external command
	my @argv = @{$self->{_external_command_argv}};
	shift @argv if ($argv[0] eq '--');
	my $empty = $self->{_empty};
	my @pre_argv;
	push @pre_argv, ($self->{_warnings} ? '--warnings' : '--nowarnings'),
	    '--nolog', '--';
	my $reducer_generator_sub;
	if ($self->{_pass_current_key}) {
	    $reducer_generator_sub = sub { 
		return dbsubprocess(@pre_argv, @argv, $_[0] // $empty);
	    };
	} else {
	    $reducer_generator_sub = sub { 
		return dbsubprocess(@pre_argv, @argv);
	     };
	};
	$self->{_reducer_generator_sub} = $reducer_generator_sub;
	print STDERR "# dbmapreduce/setup: external command is " . join(" ", @pre_argv, @argv) . "\n" if ($self->{_debug} > 2);
    } elsif (defined($self->{_filter_generator_code})) { 
	my $reducer_generator_sub;
	if (ref($self->{_filter_generator_code}) eq 'CODE') {
	    print STDERR "# dbmapreduce/setup: direct code assignment for reducer sub\n" if ($self->{_debug});
	    $reducer_generator_sub = $self->{_filter_generator_code};
	} else {
	    my $sub_code;
	    $sub_code = 
		"use Fsdb::Filter::dbpipeline qw(:all);\n" . 
		$included_code . 
		'$reducer_generator_sub = sub {' . "\n" .
		$self->{_filter_generator_code} . 
		"\n\t;\n};\n";
	    print STDERR "# dbmapreduce/setup: sub_code: $sub_code" if ($self->{_debug});
	    eval $sub_code;
	    $@ && croak $self->{_prog} . ": error evaluating user-provided reducer sub:\n$sub_code\nerror is: $@.\n";
	};
	$self->{_reducer_generator_sub} = $reducer_generator_sub;
    } else {
	croak $self->{_prog} . ": reducer not specified.\n";
    };

    #
    # do we need to group the keys for the user?
    #
    my($input_reader_aref) = ();
    my $raw_to_raw = ($#{$self->{_external_command_argv}} >= 0 && $self->{_reducer_is_multikey_aware});
    if ($raw_to_raw) {
	# external and we're good?  just hook it together
	# (test case: dbmapreduce_cat.cmd)
	$input_reader_aref = [-raw_fh => 1];
    } else {
	push (@$input_reader_aref, -comment_handler => $self->create_tolerant_pass_comments_sub('_cat_writer'));
    };
    push(@$input_reader_aref, -header => $self->{_header}) if (defined($self->{_header}));
    if ($self->{_pre_sorted}) {
	$self->finish_io_option('input', @$input_reader_aref);
    } else {
	# not pre-sorted, so do lexical sort
	my $sort_column = defined($self->{_key_column}) ? $self->{_key_column} : '0';
	my(@sort_args) = ('--nolog');
	push(@sort_args, '--header' => $self->{_header}) if (defined($self->{_header}));
	push(@sort_args, $sort_column);
        my($new_reader, $new_fred) = dbpipeline_filter(
		$self->{_input},
		$input_reader_aref,
		dbsort(@sort_args));
	$self->{_pre_sorted_input} = $self->{_input};
	$self->{_in} = $new_reader;
	$self->{_sorter_fred} = $new_fred;
	#
	# We will join the sorter in finish().
	#
    };

    #
    # figure out key column's name, now that we've done setup
    #
    if ($raw_to_raw) {
	# raw, so no parsing input at all
	$self->{_key_coli} = undef;
    } elsif (defined($self->{_key_column})) {
	$self->{_key_coli} = $self->{_in}->col_to_i($self->{_key_column});
	croak $self->{_prog} . ": key column " . $self->{_key_column} . " is not in input stream.\n"
	    if (!defined($self->{_key_coli}));
    } else {
	# default to first column
	$self->{_key_coli} = 0;
	$self->{_key_column} = $self->{_in}->i_to_col(0);
    };

    #
    # setup the postprocessing thread
    #
    $self->_setup_reducer();

    $self->{_reducer_invocation_count} = 0;
#    $SIG{'PIPE'} = 'IGNORE';
}



=head2 _setup_reducer

    _setup_reducer

(internal)  
One Fred that runs the reducer and produces output.
C<_reducer_queue> is sends the new key,
then a Fsdb stream, then EOF (undef)
for each group.
We setup the output, suppress all but the first header,
and add in the keys if necessary.

=cut

sub _setup_reducer() {
    my($self) = @_;

    if ($self->{_reducer_is_multikey_aware}) {
#	croak "case not yet handled--need to verify correct sort order\n" if ($self->{_pre_sorted} == 1);
	# No need to do input checking,
	# and reducer promises to handle whatever we give it,
	# and we assume it outputs the key, so
	# just start the reducer on our own input and run it here.
	my $reducer = &{$self->{_reducer_generator_sub}}();
	$reducer->parse_options('--input' => $self->{_in},
		    '--output' => $self->{_output},
		    '--saveoutput' => \$self->{_out},
		    '--noclose');
	$reducer->setup();
	$self->{_multikey_aware_reducer} = $reducer;
	return;
    } else {
	# do nothing; we do our work below
    };
}

=head2 _key_to_string

    $self->_key_to_string($key)

Convert a key (maybe undef) to a string for status messages.

=cut

sub _key_to_string($$) {
    my($self, $key) = @_;
    return defined($key) ? $key  : '(undef)';
}


=head2 _open_new_key

    _open_new_key

(internal)

Note that new_key can be undef if there was no input.

=cut

sub _open_new_key {
    my($self, $new_key) = @_;

    print STDERR "# dbmapreduce: _open_new_key on " . $self->_key_to_string($new_key) . "\n" if ($self->{_debug} >= 2);

    $self->{_current_key} = $new_key;

    # If already running and can handle multiple tags, just keep going.
    die "internal error: no more multikey here\n" if ($self->{_reducer_is_multikey_aware});

    #
    # make the reducer
    #
    my $output_file = Fsdb::Support::NamedTmpfile::alloc($self->{_tmpdir});
    my @reducer_modules;
    push(@reducer_modules, &{$self->{_reducer_generator_sub}}($new_key));
    if ($self->{_copy_fscode}) {
	push(@reducer_modules, dbfilealter('--nolog', '-F', $self->{_in}->fscode()));
    };
    if ($self->{_prepend_key}) {
	# croak $self->{_prog} . ": no key_column\n" if (!defined($self->{_key_column}));
	push(@reducer_modules, dbcolcreate('--no-recreate-fatal', '--nolog', '--first', '-e', $new_key // $self->{_empty}, $self->{_key_column}));
    };
    print STDERR "# reducer output to $output_file (in process $$)\n" if ($self->{_debug});
#    $reducer_modules[$#reducer_modules]->parse_options('--output' => $output_file);
    unshift(@reducer_modules, '--output' => $output_file);
    my %work_queue_entry;
    $work_queue_entry{'status'} = 'running';
    $work_queue_entry{'output'} = $output_file;
    my $debug = $self->{_debug};
    my($to_reducer_writer, $reducer_fred) = dbpipeline_sink([-clone => $self->{_in}], 
	'--fred_description' => 'dbmapreduce:dbpipeline_sink(to_reducer)',
	'--fred_exit_sub' => sub {
	    $work_queue_entry{'status'} = 'done';
	    print STDERR "# dbmapreduce:reducer: output $output_file\n" if ($debug);
	    print STDERR "# dbmapreduce:reducer: zero size $output_file\n" if (-z $output_file);
	}, @reducer_modules); 	
    $work_queue_entry{'fred'} = $reducer_fred;

    $self->{_to_reducer_writer} = $to_reducer_writer;
    $self->{_current_reducer_fastpath_sub} = $to_reducer_writer->fastpath_sub();
    push (@{$self->{_work_queue}}, \%work_queue_entry);
}

=head2 _close_old_key

    _close_old_key

Internal, finish a tag.

=cut

sub _close_old_key {
    my($self, $key, $final) = @_;

    print STDERR "# dbmapreduce: _close_old_key on " . $self->_key_to_string($key) . "\n" if ($self->{_debug} >= 2);

    if (!defined($key)) {
	croak $self->{_prog} . ": internal error: _close_old_key called on non-final null-key.\n"
	    if (!$final);
    };
    die "internal error: no more multikey here\n" if ($self->{_reducer_is_multikey_aware});

    croak $self->{_prog} . ": internal error: current key doesn't equal prior key " . $self->_key_to_string($self->{_current_key}) . " != key " . $self->_key_to_string($key) . "\n"
	if (defined($key) && $self->{_current_key} ne $key);
    # finish the reducer
    print STDERR "# dbmapreduce: _close_old_key closing reducer ($key)\n" if ($self->{_debug} >= 2);
    $self->{_to_reducer_writer}->close;
}

=head2 _check_finished_reducers

    $self->_check_finished_reducers($force);

Internal: see if any reducer freds finished, optionally $FORCE-ing 
all to finish.

This routine also enforces a maximum amount of parallelism, blocking us when we have too
many reducers running.

=cut

sub _check_finished_reducers($$) {
    my($self, $force) = @_;

    my $force_status = ($force ? "forced" : "optional");
    my $backlog = $#{$self->{_work_queue}} + 1;
    $self->{_cat_writer}->write_rowobj("# dbmapreduce: test_parallelism backlog $backlog, max $self->{_max_parallelism}\n") if ($self->{_test_parallelism});
    if ($backlog >= $self->{_max_parallelism}) {
	$force = 2;
	$force_status = "backlog-forced";
    }

    print STDERR "# dbmerge:_check_finished_reducers: $force_status\n" if ($self->{_debug});
    for(;;) {
        my $fred_or_code = Fsdb::Support::Freds::join_any();
	last if (ref($fred_or_code) eq '');
	croak "dbmapreduce: reducer failed\n"
	    if ($fred_or_code->exit_code() != 0);
	print STDERR "# dbmerge:_check_finished_reducers: merged fred " . $fred_or_code->info() . "\n" if ($self->{_debug});
    };
    #
    # Reducers finish-sub has adjusted the work queue.
    # Try to push out output.
    # Be forceful (and block) if required.
    #
    while ($#{$self->{_work_queue}} >= 0) {
	my $work_queue_href = $self->{_work_queue}->[0];
	if ($force) {
	    my $fred = $work_queue_href->{fred};
	    print STDERR "# dbmerge:_check_finished_reducers: blocking on pending fred " . $fred->info() . "\n" if ($self->{_debug});
	    my $exit_code = $fred->join();
	    croak "dbmapreduce: reducer " . $fred->info() . " failed, exit $exit_code\n" if ($exit_code != 0);
	    croak "dbmapreduce: reducer didn't leave status done\n"
		if ($work_queue_href->{status} ne 'done');
	};
	if ($work_queue_href->{status} ne 'done') {
	    croak $self->{_prog} . ": internal error, reducer refused to complete\n" if ($force);
	    last;
	};
	# this one is done, send it to output
	my $output = $work_queue_href->{output};
	print STDERR "# dbmerge->_check_finished_reducers: done with output $output\n" if ($self->{_debug});
	$self->{_cat_writer}->write_rowobj([$output]);
	shift(@{$self->{_work_queue}});
    };
}



=head2 _mapper_run

    $filter->_mapper_run();

Internal: run over each rows, grouping them.
Fork off reducer as necessary.

=cut
sub _mapper_run($) {
    my($self) = @_;

    $self->{_work_queue} = [];   # track running reducers
    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $reducer_fastpath_sub = undef;

    #
    # output merger
    #
    print STDERR "# opening dbfilecat\n" if ($self->{_debug});
    my(@writer_args) = (-cols => [qw(filename)], -outputheader => 'never', -autoflush => 1);
    my($cat_writer, $cat_fred) = dbpipeline_sink(\@writer_args,
	'--fred_description' => 'dbmapreduce:dbpipeline_sink(cat_writer)',
	'--output' => $self->{_output},
	dbfilecat(qw(--nolog --xargs --removeinputs)));
    croak $self->{_prog} . ": cannot invoke dbfilecat.\n"
	if ($cat_writer->error);
    $self->{_cat_writer} = $cat_writer;
    $self->{_cat_fred} = $cat_fred;

    # read data
    my($last_key) = undef;
    my $fref;
    my $key_coli = $self->{_key_coli};
    $self->{_key_counts} = {};
    my $nrows = 0;
    my $debug = $self->{_debug};
    while ($fref = &$read_fastpath_sub()) {
	# print STDERR "data line: " . join("  ", @$fref) . "\n";
        my($key) = $fref->[$key_coli];
    
        if (!defined($last_key) || $key ne $last_key) {
            # start a new one
            # check for out-of-order duplicates
            if ($self->{_pre_sorted} == 1) {
                croak $self->{_prog} . ": single key ``$key'' split into multiple groups, selection of -S was invalid\n"
                    if (defined($self->{_key_counts}{$key}));
                $self->{_key_counts}{$key} = 1;
            };
            # finish off old one?
            if (defined($last_key)) {
                $self->_close_old_key($last_key);
		$self->_check_finished_reducers(0);
            };
            $self->_open_new_key($key);
            $last_key = $key;
	    $reducer_fastpath_sub = $self->{_current_reducer_fastpath_sub};
	    die "no reducer\n" if (!defined($reducer_fastpath_sub));
        };
        # pass the data to be reduced
	&{$reducer_fastpath_sub}($fref);
    };

    if (!defined($last_key)) {
	# no input data, so write a single null key
        $self->_open_new_key(undef);
    };

    # print STDERR "done with input, last_key=$last_key\n";
    # close out any pending processing? (use the force option)
    $self->_close_old_key($last_key, 1);
    $self->_check_finished_reducers(1);
    # will clean up cat_writer in finish
}


=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run($) {
    my($self) = @_;

    if ($self->{_reducer_is_multikey_aware}) {
	$self->{_multikey_aware_reducer}->run();
    } else {
	$self->_mapper_run();
    };
}

=head2 finish

    $filter->finish();

Internal: write trailer.

=cut

sub finish($) {
    my($self) = @_;

    #
    # Join any pending Freds.
    #
    if ($self->{_sorter_fred}) {
        print STDERR "# mapreduce main: join sorter\n"
	    if ($self->{_debug});
        $self->{_sorter_fred}->join();
	croak $self->{_prog} . ": input sorter failed: " . $self->{_sorter_fred}->error()
	    if ($self->{_sorter_fred}->error());
    };

    if ($self->{_reducer_is_multikey_aware}) {
	$self->{_multikey_aware_reducer}->finish();
	# output our log message, in-line
	$self->SUPER::finish();
    } else {
	# output log message by sending it all to cat_writer (a hack)
	$self->{_out} = $self->{_cat_writer};
	$self->SUPER::finish();  # will close it
	$self->{_cat_writer}->close;
        print STDERR "# mapreduce main: join dbfilecat\n"
	    if ($self->{_debug});
	$self->{_cat_fred}->join();
	if (my $error = $self->{_cat_fred}->error()) {
	    croak $self->{_prog} . ": dbfilecat erred: $error";
	};
    };
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2016 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
