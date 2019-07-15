#!/usr/bin/perl -w

#
# dbjoin.pm
# Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbjoin;

=head1 NAME

dbjoin - join two tables on common columns

=head1 SYNOPSIS

    dbjoin [-Sid] --input table1.fsdb --input table2.fsdb [-nNrR] column [column...]

OR

    cat table1.fsdb  | dbjoin [-Sid] --input table2.fsdb [-nNrR] column [column...]

=head1 DESCRIPTION

Does a natural, inner join on TABLE1 and TABLE2 
the specified columns.  With the C<-a> option, or 
with C<-t outer> it will do a natural, full outer join.

(Database review:
inner joints output records only when there are matches in both tables
and will omit records that do not match.
Outer joins output all records from both tables, 
filling with the empty value as needed.
Right (left) outer joins keep all elements of the right (left)
table, even those that don't match in the other table.)

By default for non-hash joins, data will be sorted lexically,
but the usual sorting options can be mixed with the column
specification.

Because two tables are required,
input is typically in files.
Standard input is accessible by the file "-".

If only one input is given, the first (left) input
is taken from stdin.

=head1 RESOURCE REQUIREMENTS AND PERFORMANCE

Joins can be expensive. 
Most databases have a query optimizer that 
knows something about the data and so can select
algorithms for efficent operation,
in Fsdb, I<you> are that optimizer.

For I<non-hash joins>:
If data is already sorted, dbjoin will run more efficiently
by telling dbjoin the data is sorted with the C<-S>.

The resource requirements L<dbjoin> vary.
If input data is sorted and C<-S> is given,
then memory consumption is bounded by the 
the sum of the largest number of records in either dataset
with the same value in the join column,
and there is no disk consumption.
If data is not sorted, then L<dbjoin> requires
disk storage the size of both input files.

One can minimize memory consumption by making sure
each record of table1 matches relatively few records in table2.
Typically this means that table2 should be the smaller.
For example, given two files: people.fsdb (schema: name iso_country_code)
and countries.fsdb (schema: iso_country_code full_country_name),
then

    dbjoin -i people.fsdb -i countries.fsdb iso_country_code

will require less memory than

    dbjoin -i countries.fsdb -i people.fsdb iso_country_code

if there are many people per country (as one would expect).
If warning "lots of matching rows accumulating in memory" appears,
this is the cause and try swapping join order.

For I<hash joins>
(that is, with C<-m righthash> or C<-m lefthash>):
all of the right table (the second input) or the left (the first)
is loaded into memory (and "hashed").
The other table need not be sorted.
Runtime is O(n), but memory is O(size of hashed table).


=head1 OPTIONS

=over 4

=item B<-a> or B<--all>

Perform a I<full outer join>,
include non-matches (each record which doesn't match at
all will appear once).
Default is an I<inner join>.

=item B<-t TYPE> or B<--type TYPE>

Explicitly specify the join type.
TYPE must be inner, outer, left (outer), right (outer).
(Recall tha inner join requires data on both sides,
outer joins keep all records from both sides for outer,
or all of the first or second input for left and right outer joins.)
Default: inner.

=item B<-m METHOD> or B<--method METHOD>

Select join method (algorithm).
Choices are merge, righthash, and lefthash.
Default: merge.

=item B<-S> or B<--pre-sorted>

assume (and verify) data is already sorted

=item B<-e E> or B<--empty E>

give value E as the value for empty (null) records

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

=item B<--help>

Show help.

=item B<--man>

Show full manual.

=back

=for comment
end_standard_fsdb_options


=head1 SAMPLE USAGE

=head2 Input:

    #fsdb sid cid
    1 10
    2 11
    1 12
    2 12

And in the file F<DATA/classes>:

    #fsdb cid cname
    10 pascal
    11 numanal
    12 os

=head2 Command:

    cat DATA/reg.fsdb | dbsort -n cid | dbjoin -i - -i DATA/classes -n cid

=head2 Output:

    #fsdb      cid     sid     cname
    10      1       pascal
    11      2       numanal
    12      1       os
    12      2       os
    # - COMMENTS:
    #  | /home/johnh/BIN/DB/dbsort -n cid
    # DATA/classes COMMENTS:
    # joined comments:
    #  | /home/johnh/BIN/DB/dbjoin - DATA/classes cid

=head1 SEE ALSO

L<Fsdb>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;
use Fsdb::Filter::dbpipeline qw(dbpipeline_filter dbsort);


=head2 new

    $filter = new Fsdb::Filter::dbjoin(@arguments);

Create a new dbjoin object, taking command-line arguments.

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
    $self->{_pre_sorted} = 0;
    $self->{_sort_argv} = [];
    $self->{_join_type} = 'inner';
    $self->{_join_method} = 'merge';
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
	'a|all!' => sub { $self->{_join_type} = 'outer'; },
	'autorun!' => \$self->{_autorun},
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'e|empty=s' => \$self->{_empty},
	'i|input=s@' => sub { $self->parse_io_option('inputs', @_); },
	'log!' => \$self->{_logprog},
	'm|method=s' => \$self->{_join_method},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'S|pre-sorted+' => \$self->{_pre_sorted},
	't|type=s' => \$self->{_join_type},
	'T|tmpdir|tempdir=s' => \$self->{_tmpdir},
	# sort key options:
	'n|numeric' => sub { $self->parse_sort_option(@_); },
	'N|lexical' => sub { $self->parse_sort_option(@_); },
	'r|descending' => sub { $self->parse_sort_option(@_); },
	'R|ascending' => sub { $self->parse_sort_option(@_); },
	'<>' => sub { $self->parse_sort_option('<>', @_); },
	) or pod2usage(2);
    croak($self->{_prog} . ": internal error, extra arguments.\n")
	if ($#argv != -1);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup($) {
    my($self) = @_;

    croak($self->{_prog} . ": no sorting key specified.\n")
	if ($#{$self->{_sort_argv}} == -1);
    croak($self->{_prog} . ": unknown join type " . $self->{_join_type} . ".\n")
	if (!($self->{_join_type} eq 'inner' || $self->{_join_type} eq 'outer' || $self->{_join_type} eq 'left' || $self->{_join_type} eq 'right'));
    croak($self->{_prog} . ": unknown join method " . $self->{_join_method} . ".\n")
	if (!($self->{_join_method} eq 'merge' || $self->{_join_method} eq 'lefthash' || $self->{_join_method} eq 'righthash'));

    $self->setup_exactly_two_inputs;

    # hash join?
    my($hashside, $fullside) = (undef, undef);
    if ($self->{_join_method} eq 'righthash') {
	($hashside, $fullside) = (1, 0);
    } elsif ($self->{_join_method} eq 'lefthash') {
	($hashside, $fullside) = (0, 1);
    };

    #
    # automatic input sorting?
    #
    if ($self->{_join_method} eq 'merge' && !$self->{_pre_sorted}) {
	my(@final_sort_argv) = @{$self->{_sort_argv}};
	unshift(@final_sort_argv, '-T', $self->{_tmpdir})
	    if (defined($self->{_tmpdir}));
	foreach (0..1) {
	    my($new_reader, $new_fred) = dbpipeline_filter($self->{_inputs}[$_], [-comment_handler => $self->create_delay_comments_sub], dbsort('--nolog', @final_sort_argv));
	    $self->{_pre_sorted_inputs}[$_] = $self->{_inputs}[$_];
	    $self->{_ins}[$_] = $new_reader;
	    $self->{_in_freds}[$_] = $new_fred;
	};
    } else {
	$self->finish_io_option('inputs', -comment_handler => $self->create_delay_comments_sub);
    };

    # can't move next check earlier; it must be fater "finish_io_option".
    croak($self->{_prog} . ": cannot handle input data with different field separators.\n")
	if (!defined($self->{_ins}[0]->compare($self->{_ins}[1])));

    #
    # figure the joined columns
    #
    my $i = 0;  # counts output columns
    my %join_keys;
    my $key;
    my @output_columns;
    my %all_keys;
    my @copy_codes = ('', '');
    my $build_key_from_hashside_code = '';
    my $build_key_from_fullside_code = '';
    my $build_hashside_result_code = '';
    my $build_output_from_hit_code = '';
    my $merge_output_from_hit_code = '';
    my $build_output_from_full_code = '';
    my @hash_input_col_to_hit_col;   # not actullay used
    my $hit_ncol = 0;
    for $key (@{$self->{_sort_argv}}) {
        next if ($key =~ /^-/);   # we deal with this later

	# figure out details for both sides
	my @col_i;
	foreach (0..1) {
	    $col_i[$_] = $self->{_ins}[$_]->col_to_i($key);
	    croak($self->{_prog} . ": column ``$key'' is not in " . ($_ == 0 ? "left" : "right") ." join source.\n") if (!defined($col_i[$_]));
	    # for merge join, details are copy
	    $copy_codes[$_] .= '$out_fref->[' . $i . '] = $frefs[' . $_ . "]->[$col_i[$_]];\n";
	    # for hash join, also build the hash key
	    if ($self->{_join_method} ne 'merge') {
		if ($_ == $hashside) {
		    $build_key_from_hashside_code .= '$key .= ' . ($i == 0 ? '' : '$fs . ') . '$fref->[' . $col_i[$_] . ']; ';
		    $build_hashside_result_code .= ($i == 0 ? '' : ", ") . '$fref->[' . $col_i[$_] . ']';
		    $hash_input_col_to_hit_col[$col_i[$_]] = $hit_ncol++;
		    $build_output_from_hit_code .= '$out_fref->[' . $i . '] = $hit->[' . $i . "];\n";
		};
		if ($_ == $fullside) {
		    $build_key_from_fullside_code .= '$key .= ' . ($i == 0 ? '' : '$fs . ') . '$fref->[' . $col_i[$_] . ']; ';
		    $build_output_from_full_code .= '$out_fref->[' . $i . '] = $fref->[' . $col_i[$_] . "];\n";
		};
	    };
	};

	push(@output_columns, $key);
        $join_keys{$key} = $i;
        $all_keys{$key} = $i;
        $i++;
    }

    #
    # and the rest
    #
    my $copy_codes = '';
    my $col_i;
    foreach $key (@{$self->{_ins}[0]->cols}) {
        next if (defined($all_keys{$key}));  # already got it
	push(@output_columns, $key);
	$col_i = $self->{_ins}[0]->col_to_i($key);
	defined($col_i) or croak("assert");
	$copy_codes[0] .= '$out_fref->[' . $i . '] = $frefs[0]->[' . $col_i . '];' . "\n";
	$all_keys{$key} = $i;
	if ($self->{_join_method} ne 'merge') {
	    if (0 == $hashside) {
		$build_hashside_result_code .= ', $fref->[' . $col_i . ']';
		my $hit_col = $hit_ncol++;
		$hash_input_col_to_hit_col[$col_i] = $hit_col;
		$build_output_from_hit_code .= '$out_fref->[' . $i . '] = $hit->[' . $hit_col . '];';
		$merge_output_from_hit_code .= '$out_fref->[' . $i . '] = $hit->[' . $hit_col . '];';
	    };
	    if (0 == $fullside) {
		$build_output_from_full_code .= '$out_fref->[' . $i . '] = $fref->[' . $col_i . '];';
	    };
	};
        $i++;
    };
    foreach $key (@{$self->{_ins}[1]->cols}) {
        next if (defined($join_keys{$key}));
        # detect duplicates that are not joined upon (error)
        # (this represents duplicate fieds in the two merged things).
        # Reject this because we don't want to silently prefer one to the other.
        if (defined($all_keys{$key})) {
	    croak($self->{_prog} . ": column $key is in both of the joined files, but is not joined upon.\nAll non-joined columns must be unique.\nBefore joining you must\nrename one of the source columns\nor remove one of the duplicate input columns.\n");
        };
	push(@output_columns, $key);
	$col_i = $self->{_ins}[1]->col_to_i($key);
	defined($col_i) or croak("assert");
	$copy_codes[1] .= '$out_fref->[' . $i . '] = $frefs[1]->[' . $col_i . '];' . "\n";
	$all_keys{$key} = $i;
	if ($self->{_join_method} ne 'merge') {
	    if (1 == $hashside) {
		$build_hashside_result_code .= ', $fref->[' . $col_i . ']';
		my $hit_col = $hit_ncol++;
		$hash_input_col_to_hit_col[$col_i] = $hit_col;
		$build_output_from_hit_code .= '$out_fref->[' . $i . '] = $hit->[' . $hit_col . '];';
		$merge_output_from_hit_code .= '$out_fref->[' . $i . '] = $hit->[' . $hit_col . '];';
	    };
	    if (1 == $fullside) {
		$build_output_from_full_code .= '$out_fref->[' . $i . '] = $fref->[' . $col_i . '];';
	    };
	};
        $i++;
    };
    $self->{_copy_codes} = \@copy_codes;

    $self->{_build_key_from_hashside_code} = $build_key_from_hashside_code;
    $self->{_build_key_from_fullside_code} = $build_key_from_fullside_code;
    $self->{_build_hashside_result_code} = $build_hashside_result_code;
    $self->{_build_output_from_hit_code} = $build_output_from_hit_code;
    $self->{_merge_output_from_hit_code} = $merge_output_from_hit_code;
    $self->{_build_output_from_full_code} = $build_output_from_full_code;

    $self->finish_io_option('output', -clone => $self->{_ins}[0], -cols => \@output_columns);

    #
    # comparision code
    #
    $self->{_compare_code} = $self->create_compare_code(@{$self->{_ins}}, 'frefs[0]', 'frefs[1]');;
    croak($self->{_prog} . ": no join field specified.\n")
	if (!defined($self->{_compare_code}));

    print "COMPARE CODE:\n\t" . $self->{_compare_code} . "\n" if ($self->{_debug});
    foreach (0..1) {
       $self->{_compare_code_ins}[$_] = $self->create_compare_code($self->{_ins}[$_], $self->{_ins}[$_], "prev_frefs[$_]", "frefs[$_]");
       croak($self->{_prog} . ": no join field specified.\n")
	    if (!defined($self->{_compare_code_ins}[$_]));
    };
}


=head2 run_merge_join

    $filter->run_merge_join();

Internal: run over each rows.

=cut
sub run_merge_join($) {
    my($self) = @_;

    # 
    # Eval compare_sub in this lexical context
    # of our variables.
    #
    my @prev_frefs;
    my @frefs;
    my(@right_frefs);
    my $compare_sub;
    my @check_compare_subs;
    my $code = '$compare_sub = ' . $self->{_compare_code} . "\n" .
	 '$check_compare_subs[0] = ' . $self->{_compare_code_ins}[0] . "\n" .
	 '$check_compare_subs[1] = ' . $self->{_compare_code_ins}[1] . "\n";
    eval $code;
    $@ && croak($self->{_prog} . ":  internal eval error in compare code: $@.\n");

    my @fastpath_subs;
    foreach (0..1) {
	$fastpath_subs[$_] = $self->{_ins}[$_]->fastpath_sub();
    };
    my $out_fastpath_sub = $self->{_out}->fastpath_sub();

    #
    # Set up some "macros".
    #
    my $out_fref = [];
    my $copy_left_to_out_fref;
    my $copy_right_to_out_fref;
    $code = '$copy_left_to_out_fref = sub {' . "\n" . $self->{_copy_codes}[0] . "\n};\n" .
	    '$copy_right_to_out_fref = sub {' . "\n" . $self->{_copy_codes}[1] . "\n};\n";
    eval $code;
    $@ && croak($self->{_prog} . ":  internal eval error in copy code: $@.\n$code\n");
    my $reset_out_fref = sub {
	$out_fref =  [ ($self->{_empty}) x $self->{_out}->ncols ];
    };
    my $emit_non_match_left = sub {
	&{$reset_out_fref}();
	&{$copy_left_to_out_fref}();
	&{$out_fastpath_sub}($out_fref);
    };
    my $emit_non_match_right = sub {
	&{$reset_out_fref}();
	&{$copy_right_to_out_fref}();
	&{$out_fastpath_sub}($out_fref);
    };
    if ($self->{_join_type} eq 'inner') {
	$emit_non_match_left = $emit_non_match_right = sub {};
    } elsif ($self->{_join_type} eq 'left') {
	$emit_non_match_right = sub {};
    } elsif ($self->{_join_type} eq 'right') {
	$emit_non_match_left = sub {};
    };
    my $advance_left = sub {
	$prev_frefs[0] = $frefs[0];
	$frefs[0] = &{$fastpath_subs[0]}();
	if (defined($frefs[0])) {
	    &{$check_compare_subs[0]}() <= 0 or 
                croak("dbjoin: left stream is unsorted, compare:\n" . "\t" . join(" ", @{$prev_frefs[0]}) . "\n\t" . join(" ", @{$frefs[0]}) . "\n");
	};
    };
    my $advance_right = sub {
	$prev_frefs[1] = $frefs[1];
	$frefs[1] = &{$fastpath_subs[1]}();
	if (defined($frefs[1])) {
	    &{$check_compare_subs[1]}() <= 0 or
                croak("dbjoin: right stream is unsorted, compare:\n" . "\t" . join(" ", @{$prev_frefs[1]}) . "\n\t" . join(" ", @{$frefs[1]}) . "\n");
	};
    };

    #
    # join the data (assumes data already sorted)
    #
    # Algorithm (standard "Sort Merge Join"):
    #
    # more: walk through left (0) until it matches right
    #    emitting non-matching records as we go
    # then we're in a match:
    #    find all matching rights and save them (maybe more than mem)
    #    then walk all matching lefts:
    #	    for each one, output all the matches against the saved rights
    #    when we get a non-matching left, discard our saved rights
    #	    and do more (above)
    # finally, we may have leftover, non-matching rights, output them as non-matches
    #
    # Oh, and along the way, verify the inputs are actually sorted.
    #
    # The above algorithm (sort/merge join) is theoretically optimal
    # at O(n log n) in n input records, but not experimentally optimal
    # if left or right is small.
    # In the current implementation, if |right| >> |left|, we lose.
    #
    # As an exercise to the reader, we could allow different
    # algorithms.  If right (or left) is small, we should just read
    # it into memory and do a hash join against it.
    # See <http://en.wikipedia.org/wiki/Hash_join> for details.
    #

    # prime the pump
    foreach (0..1) {
	$frefs[$_] = &{$fastpath_subs[$_]}();
    };

    #
    # Main loop: walk through left
    #
until_eof:
    for (;;) {
	# eof on either stream? quit main loop
	last if (!defined($frefs[0]) || !defined($frefs[1]));

	# eat data until we have a match
	my $left_right_cmp;

until_match:
	for (;;) {
	    defined($frefs[0]) or croak("assert");
	    defined($frefs[1]) or croak("assert");

	    $left_right_cmp = &{$compare_sub}();

	    if ($left_right_cmp < 0) {
		# left wins, so eat left
		&{$emit_non_match_left}();
		&{$advance_left}();
		last until_eof if (!defined($frefs[0]));
	    } elsif ($left_right_cmp > 0) {
		# right wins, eat right
		&{$emit_non_match_right}();
		&{$advance_right}();
		last until_eof if (!defined($frefs[1]));
	    } else {
		last until_match;
	    };
	};

	#
	# match, whoo hoo!
	#
	$left_right_cmp == 0 or croak("assert");
	defined($frefs[0]) or croak("assert");
	defined($frefs[1]) or croak("assert");

	# accumulate rights
	# Sigh, we save them in memory.
	# xxx: we should really spill to disk if we get too many.
	@right_frefs = ();
accumulate_rights:
	for (;;) {
	    push(@right_frefs, $frefs[1]);
	    warn "internal warning: dbjoin: lots of matching rows accumulating in memory. Fixes: dbjoin code can spill to disk (not implemented) or dbjoin user can perhaps swap file orders.\n"
		if ($#right_frefs == 2000);   # just emit warning once
	    &{$advance_right}();
	    last accumulate_rights if (!defined($frefs[1]));
	    $left_right_cmp = &{$compare_sub}();
	    last accumulate_rights if ($left_right_cmp != 0);
	};
	(!defined($frefs[1]) || $left_right_cmp != 0) or croak("assert");
	#
	# Ok, this is a bit gross, but we do it anyway.
	# Right is now one beyond a match.
	# Save it aside and we'll come back to it later.
	# This way we can iterate with $frefs[1] over our saved @right_frefs,
	# keeping our &{$fns}()'s happy.
	#
	my $right_fref_past_match = $frefs[1];

	# now walk lefts

	&{$reset_out_fref}();
walk_lefts:
	for (;;) {
	    &{$copy_left_to_out_fref}();
	    foreach my $matching_right (@right_frefs) {
		$frefs[1] = $matching_right;  # hacky, but satisifys next line's call
	    	&{$copy_right_to_out_fref}();
		&{$out_fastpath_sub}($out_fref);
	    };
	    &{$advance_left}();
	    last walk_lefts if (!defined($frefs[0]));
	    $left_right_cmp = &{$compare_sub}();
	    last walk_lefts if ($left_right_cmp != 0);
	};
	(!defined($frefs[0]) || $left_right_cmp != 0) or croak("assert");
	# Put back our one-beyond right.  Could even be eof.
	$frefs[1] = $right_fref_past_match; 

	# ok, we're now past a match,
	# and maybe at eof on one stream.
	# loop back to try again.
	(!defined($frefs[0]) || !defined($frefs[1]) || $left_right_cmp != 0) or croak("assert");
    };

    # Ok, now at least one side or the other is eof.
    # so drain both sides.
    while (defined($frefs[0])) {
	&{$emit_non_match_left}();
	&{$advance_left}();
    };
    while (defined($frefs[1])) {
	&{$emit_non_match_right}();
	&{$advance_right}();
    };

    # Reap the theads to suppress a warning (they SHOULD be done
    # because they gave us eof, but who knows).
    if (!$self->{_pre_sorted}) {
	foreach (0..1) {
	    $self->{_in_freds}[$_]->join();
	};
    };
}


=head2 run_hash_join

    $filter->run_hash_join();

Internal: run over each rows, doing a hash join.

=cut
sub run_hash_join($$$) {
    my($self, $hashside, $fullside) = @_;

    #
    # A basic hash join:  (This is Wikipedia's "Classic hash join".)
    #
    # Build phase:
    #
    # Load the hashed table into memory,
    # building a hash table %hashed_table.
    #
    # Probe phase:
    #
    # Then walk the larger table,
    # checking against the hash table for matches.
    #
    # We currently require that it fits in memory.
    #

    #
    # Build.
    #
    my @fastpath_subs;
    foreach (0..1) {
	$fastpath_subs[$_] = $self->{_ins}[$_]->fastpath_sub();
    };
    my $out_fastpath_sub = $self->{_out}->fastpath_sub();

    my %hashed_table;
    my %hashed_table_overflow;
    my $fref;
    my $overflow_count = 0;

    my $build_key_from_hashside;
    my $build_key_from_fullside;
    my $fs = $self->{_out}->fs;
    my $code = '$build_key_from_hashside = sub {' . "\n\t" . 'my($key) = ""; ' . $self->{_build_key_from_hashside_code} .
		"\n\t" . 'my @a = ( ' . $self->{_build_hashside_result_code} . ");\n\t" . 'return($key,\@a);' . "\n};\n" .
		'$build_key_from_fullside = sub {' . "\n\t" . 'my($key) = ""; ' . $self->{_build_key_from_fullside_code} .
		"\n\t" . 'return $key;' . "\n};\n";
    eval $code;
    $@ && croak($self->{_prog} . ":  internal eval error in hash build code: $@.\n$code\n");

    while ($fref = &{$fastpath_subs[$hashside]}()) {
        #
	# build the hash entry
        #
        # Note that each entry in %hashed_table is either an ARRAY,
        # in which case it is the ONE hit.
        # Or it's a SCALAR (ref == ''), in which case
        # there is an array of matchines in $hashed_table_overflow{$key}.
        #
        # This two-level structure avoids building arrays of arrays
        # in the common case of one reference for each element.
        #
	my($key, $aref) = &{$build_key_from_hashside}($fref);
	if (defined($hashed_table{$key})) {
	    # overflow?
	    if (ref($hashed_table{$key}) eq '') {
		# already overflowed
		push(@{$hashed_table_overflow{$key}}, $aref);
	    } else {
		# new overflow
		croak("internal error: confused about overflow on $key\n")
		    if (defined($hashed_table_overflow{$key}));
		my @new_overflow = ($hashed_table{$key}, $aref);
		$hashed_table_overflow{$key} = \@new_overflow;
		$hashed_table{$key} = 1;   # mark new overflow
		$overflow_count++;
	    };
        } else {
	    $hashed_table{$key} = $aref;
	};
    };

    my %hashed_table_unmatched;
    foreach (keys %hashed_table) {
	$hashed_table_unmatched{$_} = 1;
    };
    my $out_fref = [];

    my $build_output_from_full;
    my $build_output_from_hit;
    my $merge_output_from_hit;
    my $empty = $self->{_empty};
    my $hit;
    my $reset_output_code = '$out_fref =  [ ($empty) x ' . $self->{_out}->ncols . " ];\n";
    $code = '$build_output_from_full = sub {' . "\n" . $reset_output_code . $self->{_build_output_from_full_code} . "\n};\n" .
	    '$build_output_from_hit = sub {' . "\n" . $reset_output_code . $self->{_build_output_from_hit_code} . "\n};\n" .
	    '$merge_output_from_hit = sub {' . "\n" . $self->{_merge_output_from_hit_code} . "\n};\n";
    eval $code;
    $@ && croak($self->{_prog} . ":  internal eval error in hash probe code: $@.\n$code\n");

    #
    # Probe.
    #
    my($show_probe_non_matches) = ($self->{_join_type} eq 'outer') ||
	($self->{_join_type} eq 'left' && $self->{_join_method} eq 'righthash') ||
	($self->{_join_type} eq 'right' && $self->{_join_method} eq 'lefthash');
    while ($fref = &{$fastpath_subs[$fullside]}()) {
	# probe and join
	my $key = &{$build_key_from_fullside}();
        $hit = $hashed_table{$key};
	if (!defined($hit)) {
	    # no match
	    if ($show_probe_non_matches) {
		&{$build_output_from_full}();
		&{$out_fastpath_sub}($out_fref);
	    };
	} else {
	    delete $hashed_table_unmatched{$key};
	    &{$build_output_from_full}();
	    if (ref($hit) eq 'ARRAY') {
		# single hit
		&{$merge_output_from_hit}();
		&{$out_fastpath_sub}($out_fref);
	    } else {
		# overflow hits
		# xxx: if you replace "my $h" with "$hit", perl-5.22.2-362.fc24.x86_64 segfaults
		foreach my $h (@{$hashed_table_overflow{$key}}) {
		    $hit = $h;
		    &{$merge_output_from_hit}();
		    &{$out_fastpath_sub}($out_fref);
		};
	    };
	};
    };

    #
    # Dump extra hashs, if necessary.
    #
    if (($self->{_join_type} eq 'outer') ||
		($self->{_join_type} eq 'left' && $self->{_join_method} eq 'lefthash') ||
		($self->{_join_type} eq 'right' && $self->{_join_method} eq 'righthash')) {
	for my $key (sort keys %hashed_table_unmatched) {
	    $hit = $hashed_table{$key};
	    if (ref($hit) eq 'ARRAY') {
		# single hit
		&{$build_output_from_hit}();
		&{$out_fastpath_sub}($out_fref);
	    } else {
		# overflow hits
		foreach $hit (@{$hashed_table_overflow{$key}}) {
		    &{$build_output_from_hit}();
		    &{$out_fastpath_sub}($out_fref);
		};
	    };
	};	
    };	
}


=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run($) {
    my($self) = @_;
    if ($self->{_join_method} eq 'merge') {
	$self->run_merge_join();
    } elsif ($self->{_join_method} eq 'righthash') {
	$self->run_hash_join(1, 0);
    } elsif ($self->{_join_method} eq 'lefthash') {
	$self->run_hash_join(0, 1);
    } else {
	croak($self->{_prog} . ": unknown join method " . $self->{_join_method} . "\n");
    };
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
