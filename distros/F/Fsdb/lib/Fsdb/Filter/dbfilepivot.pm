#!/usr/bin/perl

#
# dbfilepivot.pm
# Copyright (C) 2011-2016 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbfilepivot;

=head1 NAME

dbfilepivot - pivot a table, converting multiple rows into single wide row

=head1 SYNOPSIS

dbfilepivot [-e empty] -k KeyField -p PivotField [-v ValueField]

=head1 DESCRIPTION

Pivot a table, converting multiple rows corresponding to the 
same key into a single wide row.

In a normalized database, one might have data with a schema like
(id, attribute, value),
but sometimes it's more convenient to see the data with a schema like
(id, attribute1, attribute2).
(For example, gnuplot's stacked histograms requires denormalized data.)
Dbfilepivot converts the normalized format to the denormalized,
but sometimes useful, format.
Here the "id" is the key, the attribute is the "pivot",
and the value is, well, the optional "value".

An example is clearer.  A gradebook usually looks like:

    #fsdb name hw_1 hw_2 hw_3
    John       97  98  99
    Paul       -   80  82

but a properly normalized format would represent it as:

    #fsdb name hw score
    John       1  97
    John       2  98
    John       3  99
    Paul       2  80
    Paul       3  82

This tool converts the second form into the first, when used as

    dbfilepivot -k name -p hw -v score

or

    dbfilepivot --possible-pivots='1 2 3' -k name -p hw -v score

Here name is the I<key> column that indicates which rows belong
to the same entity,
hw is the I<pivot> column that will be indicate which column
in the output is relevant,
and score is the I<value> that indicates what goes in the
output.

The pivot creates a new column C<key_tag1>, C<key_tag2>, etc.
for each tag, the contents of the pivot field in the input.
It then populates those new columns with the contents of the value field
in the input.

If no value column is specified, then values are either empty or 1.

Dbfilepivot assumes all lines with the same key are adjacent
in the input source, like L<dbmapreduce(1)> with the F<-S> option.
To enforce this invariant, by default, it I<requires> input be sorted by key.

There is no requirement that the pivot field be sorted (provided the key field is already sorted).

By default, dbfilepivot makes two passes over its data
and so requires temporary disk space equal to the input size.
With the B<--possible-pivots> option, the user can specify pivots
and skip the second pass and avoid temporary data storage.

Memory usage is proportional to the number of unique pivot values.

The inverse of this commend is L<dbcolsplittorows>.


=head1 OPTIONS

=over 4

=item B<-k> or B<--key> KeyField

specify which column is the key for grouping.
Required (no default).

=item B<-p> or B<--pivot> PivotField

specify which column is the key to indicate which column in the output
is relevant.
Required (no default).

=item B<-v> or B<--value> ValueField

Specify which column is the value in the output.
If none is given, 1 is used for the value.

=item B<--possible-pivots PP>

Specify all possible pivot values as PP, a whitespace-separated list.
With this option, data is processed only once (not twice).

=item B<-C S> or B<--element-separator S>

Specify the separator I<S> used to join the input's key column
with its contents.
(Defaults to a single underscore.)

=item B<-e E> or B<--empty E>

give value E as the value for empty (null) records

=item B<-S> or B<--pre-sorted>

Assume data is already grouped by key.
Provided twice, it removes the validation of this assertion.
By default, we sort by key.

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

=item B<--help>

Show help.

=item B<--man>

Show full manual.

=back

=for comment
end_standard_fsdb_options


=head1 SAMPLE USAGE

=head2 Input:

	#fsdb name hw score
	John       1  97
	John       2  98
	John       3  99
	Paul       2  80
	Paul       3  82

=head2 Command:

    cat data.fsdb | dbfilepivot -k name -p hw -v score

=head2 Output:

	#fsdb name hw_1 hw_2 hw_3
	John	97	98	99
	Paul	-	80	82
	#   | dbfilepivot -k name -p hw -v score

=head1 SEE ALSO

L<Fsdb(3)>.
L<dbcolmerge(1)>.
L<dbcolsplittorows(1)>.
L<dbcolsplittocols(1)>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;
use Fsdb::IO::Replayable;
use Fsdb::Filter::dbpipeline qw(dbpipeline_filter dbsort);


=head2 new

    $filter = new Fsdb::Filter::dbfilepivot(@arguments);

Create a new dbfilepivot object, taking command-line arguments.

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
    $self->{_elem_separator} = '_';
    $self->{_tmpdir} = defined($ENV{'TMPDIR'}) ? $ENV{'TMPDIR'} : "/tmp";
    $self->{_key_column} = undef;
    $self->{_pivot_column} = undef;
    $self->{_value_column} = undef;
    $self->{_pre_sorted} = 0;
    $self->{_sort_order} = undef;
    $self->{_sort_as_numeric} = undef;
    $self->{_possible_pivots} = undef;
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
	'C|element-separator=s' => \$self->{_elem_separator},
	'd|debug+' => \$self->{_debug},
	'e|empty=s' => \$self->{_empty},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'k|key=s' => \$self->{_key_column},
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'p|pivot=s' => \$self->{_pivot_column},
	'possible-pivots=s' => \$self->{_possible_pivots},
	'S|pre-sorted+' => \$self->{_pre_sorted},
	'T|tmpdir|tempdir=s' => \$self->{_tmpdir},
	'v|value=s' => \$self->{_value_column},
	# sort key options:
	'n|numeric' => sub { $self->{_sort_as_numeric} = 1; },
	'N|lexical' => sub { $self->{_sort_as_numeric} = undef; },
	'r|descending' => sub { $self->{_sort_order} = -1; },
	'R|ascending' => sub { $self->{_sort_order} = 1; },
	) or pod2usage(2);
    pod2usage(2) if ($#argv != -1);
}

=head2 _find_possible_pivots

    $filter->_find_possible_pivots();

Internal: scan input data to find all possible pivot values.

Returns npivots, pivots_aref.

=cut

sub _find_possible_pivots($) {
    my($self) = @_;

    #
    # Read the data to find all possible pivots,
    # saving a copy as we go.
    #
    $self->{_replayable} = new Fsdb::IO::Replayable(-writer_args => [ -clone => $self->{_in} ], -reader_args => [ -comment_handler => $self->create_pass_comments_sub ]);
    my $save_out = $self->{_replayable_writer} = $self->{_replayable}->writer;
    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $save_write_fastpath_sub = $save_out->fastpath_sub;
    my $fref;
    my %pivots;
    my $npivots = 0;
    my $loop = q(
	    # first pass: reading data to find all possible pivots
	    while ($fref = &$read_fastpath_sub) {
		my $value = $fref->[) . $self->{_pivot_coli} . q@];
		if ($value ne '@ . $self->{_empty} . q@') {
		    $npivots++ if (!defined($pivots{$value}));
		    $pivots{$value} = 1;
		};
		&$save_write_fastpath_sub($fref);
	    };
	@;
    print $loop if ($self->{_debug});
    eval $loop;
    $@ && croak $self->{_prog} . ": internal eval error: $@.\n";

    if (defined($self->{_sorter_fred})) {
	$self->{_sorter_fred}->join();
	$self->{_sorter_fred} = undef;
    };

    $self->{_replayable}->close;

    my(@pivots) = keys %pivots;

    return ($npivots, \@pivots);
}


=head2 _given_possible_pivots

    $filter->_given_possible_pivots();

Internal: parse option of possible pivots.

Returns npivots, pivots_href.

=cut

sub _given_possible_pivots($) {
    my($self) = @_;

    #
    # All possible pivots are given by the user.
    #
    my @pivots = split(/\s+/, $self->{_possible_pivots});
    return ($#pivots + 1, \@pivots);
}


=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    croak $self->{_prog} . ": invalid empty value (single quote).\n"
	if ($self->{_empty} eq "'");

    #
    # guarantee data is sorted
    # (swap reader if necessary)
    if ($self->{_pre_sorted}) {
	# pre-sorted, so just read it
	$self->finish_io_option('input', -comment_handler => $self->create_delay_comments_sub);
	$self->{_sorter_fred} = undef;
    } else {
	# not sorted, so sort it and read that
	my @sort_args = ('--nolog', $self->{_key_column});
	unshift(@sort_args, '--descending') if ($self->{_sort_order} == -1);
	unshift(@sort_args, ($self->{_sort_as_numeric} ? '--numeric' : '--lexical'));
	my($new_reader, $new_fred) = dbpipeline_filter($self->{_input}, [-comment_handler => $self->create_delay_comments_sub], dbsort(@sort_args));
	$self->{_pre_sorted_input} = $self->{_input};
	$self->{_in} = $new_reader;
	$self->{_sorter_fred} = $new_fred;
    };

    pod2usage(2) if (!defined($self->{_key_column}));
    $self->{_key_coli} = $self->{_in}->col_to_i($self->{_key_column});
    croak $self->{_prog} . ": key column " . $self->{_key_column} . " is not in input stream.\n"
	    if (!defined($self->{_key_coli}));

    pod2usage(2) if (!defined($self->{_pivot_column}));
    $self->{_pivot_coli} = $self->{_in}->col_to_i($self->{_pivot_column});
    croak $self->{_prog} . ": pivot column " . $self->{_pivot_column} . " is not in input stream.\n"
	    if (!defined($self->{_pivot_coli}));

    if (defined($self->{_value_column})) {
	$self->{_value_coli} = $self->{_in}->col_to_i($self->{_value_column});
        croak $self->{_prog} . ": value column " . $self->{_value_column} . " is not in input stream.\n"
	    if (!defined($self->{_value_coli}));
    };

    my($npivots, $pivots_aref) = (defined($self->{_possible_pivots}) ? $self->_given_possible_pivots() : $self->_find_possible_pivots());
    croak $self->{_prog} . ": no input data or pivots\n"
	if ($npivots == 0);

    #
    # Now that we know the pivots, make the new columns.
    #
    # kill the old pivot column, and value if given.
    my @new_cols = grep(!($_ eq $self->{_pivot_column} ||
			  (defined($self->{_value_column}) && $_ eq $self->{_value_column})),
		        @{$self->{_in}->cols});
    $self->finish_io_option('output', -clone => $self->{_in}, -cols => \@new_cols, -outputheader => 'delay');
    my %tag_colis;
    my %new_columns;
    foreach (sort @$pivots_aref) {
	# xxx: could try to sort numerically if all pivots are numbers
	my $new_column = $self->{_pivot_column} . $self->{_elem_separator} . $_;
	$new_columns{$new_column} = 1;
        $self->{_out}->col_create($new_column)
	    or croak $self->{_prog} . ": cannot create column $new_column (maybe it already existed?)\n";
	$tag_colis{$_} = $self->{_out}->col_to_i($new_column);
    };
    $self->{_tag_colis_href} = \%tag_colis;
    # write the mapping code.
    my $old_mapping_code = '';
    # first the old bits
    foreach (@{$self->{_in}->cols}) {
	next if ($_ eq $self->{_pivot_column} ||
			  (defined($self->{_value_column}) && $_ eq $self->{_value_column}));
	$old_mapping_code .= '$nf[' . $self->{_out}->col_to_i($_) . '] = ' .
			    '$fref->[' . $self->{_in}->col_to_i($_) . '];' . "\n";
    };
    $self->{_old_mapping_code} = $old_mapping_code;
    # and initialize the new
    my $new_initialization_code = '';
    foreach (sort keys %new_columns) {
	$new_initialization_code .= '$nf[' . $self->{_out}->col_to_i($_) . '] = ' . "\n";
    };
    $new_initialization_code .= "\t'" . $self->{_empty} . "';\n";
    $self->{_new_initialization_code} = $new_initialization_code;
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $in_reader = (defined($self->{_replayable}) ? $self->{_replayable}->reader : $self->{_in});
    my $read_fastpath_sub = $in_reader->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    #
    # Basic idea: mapreduce on the input
    # with a multikey aware reducer.
    #
    # We don't actually run mapreduce
    # because (sadly) it's easier to do it in-line
    # given we assume sorted input.
    #
    my $emit_nf_code = '&$write_fastpath_sub(\@nf);';
    my $check_ordering_code = '
	die "' . $self->{_prog} . q': keys $old_key and $new_key are out-of-order\n" if ($old_key gt $new_key);
    ';
    $check_ordering_code = '' if ($self->{_pre_sorted} > 1);
    my $value_value = (defined($self->{_value_column})) ? '$fref->[' . $self->{_value_coli} . ']' : '1';
    my $tag_colis_href = $self->{_tag_colis_href};
    my($loop) = q'
    {
	my $old_key = undef;
        my $fref;
	my @nf;
	while ($fref = &$read_fastpath_sub()) {
	    my $new_key = $fref->[' . $self->{_key_coli} . '];
	    if (!defined($old_key) || $old_key ne $new_key) {
		if (defined($old_key)) {
		    ' . $emit_nf_code . 
		    $check_ordering_code . '
		};
		' . $self->{_new_initialization_code} . '
		' . $self->{_old_mapping_code} . '
		$old_key = $new_key;
	    };
	    my $pivot_value = $fref->[' . $self->{_pivot_coli} . '];
	    my $target_coli = $tag_colis_href->{$pivot_value};
	    die $self->{_prog} . ": unanticipated pivot value $pivot_value (forgot it in --possible-pivots?).\n"
		if (!defined($target_coli));
	    $nf[$target_coli] = ' . $value_value . ';
        };
	if (defined($old_key)) {
	    ' . $emit_nf_code . "
	};
    }\n";
    print $loop if ($self->{_debug});
    eval $loop;
    if ($@) {
	# propagate sort failure cleanly
	if ($@ =~ /^$self->{_prog}/) {
	    croak "$@";
	} else {
	    croak $self->{_prog} . ": internal eval error: $@.\n";
	};
    };

    # If single pass, we may need to collect this thread here.
    if (defined($self->{_sorter_fred})) {
	$self->{_sorter_fred}->join();
	$self->{_sorter_fred} = undef;
    };

}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 2011-2016 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
