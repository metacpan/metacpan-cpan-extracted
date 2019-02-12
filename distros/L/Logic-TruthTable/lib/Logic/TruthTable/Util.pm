=head1 NAME

Logic::TruthTable::Util - provide utility functions to Logic::TruthTable

=cut

package Logic::TruthTable::Util;

use strict;
use warnings;
use 5.016001;

use Carp;
use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	all => [ qw(
		push_minterm_columns
		push_maxterm_columns
		var_column
		shift_terms
		rotate_terms
		reverse_terms
	) ],
);

our @EXPORT_OK = (
	@{$EXPORT_TAGS{all}},
);

our $VERSION = 1.00;

=head1 DESCRIPTION

This module provides various utilities designed for (but not limited to)
creating or manipulating term lists for Logic::TruthTable.

=cut

=head2 FUNCTIONS

=head3 push_minterm_columns()

=head3 push_maxterm_columns()

    push_minterm_columns($idx, $dir, \@colx, \@coly, \@colz);

or

    push_maxterm_columns($idx, $dir, \@colx, \@coly, \@colz);

Often the outputs to be simulated by boolean expressions are values that
are split across more than one column. For example, say that you want
to model a function to direct a pointer that uses the eight
L<cardinal and ordinal |https://en.wikipedia.org/wiki/Points_of_the_compass#Compass_point_names>
compass directions, from North (value 0) to NorthWest (value 7).

Numbering these directions takes three bits, which means you'd need three
columns to represent them.

To make it easier to create these columns, C<push_minterm_columns()>
(or, if you prefer, C<push_maxterm_columns()>) will take a value
from your function and, for each set bit (or if using maxterms,
unset bit), will push the minterm (or maxterm) onto each array
corresponding to its column.

For example, if the value of row 20 is 5 (in binary C<0b101>),
then a call to C<push_minterm_columns(20, 5, \@x, \@y, \@z);>
will push 20 onto array variables C<@x>, and C<@z>, while a call to
C<push_maxterm_columns(20, 5, \@x, \@y, \@z);> will push a 20 onto
array variable C<@y> only.

Bit values past the available columns will simply be dropped, while
excess columns will either never have terms pushed on them
(C<push_minterm_columns()>) or always have terms pushed on them
(C<push_maxterm_columns()>).

For example:

    #
    # Each column gets its own term list.
    # The don't-care terms will be common across
    # all columns.
    #
    my(@col2, @col1, @col0, @dontcares);

    #
    # For each cell, return a direction.
    #
    for my $idx (0..63)
    {
        my $dir = sp_moveto($idx);

        #
        # In this example, a cell that cannot be exited cannot
        # be entered either, so mark it as a don't-care.
        #
        if ($dir < 0 or $dir > 7)
        {
            push @dontcares, $idx;
        }
        else
        {
            #
            # For any set bit in $dir, push $idx onto the corresponding
            # column list.
            #
            push_minterm_columns($idx, $dir, \@col2, \@col1, \@col0);
        }
    }

You will then have the minterms available for each column of your
truth table.

    my $dir_table = Logic::TruthTable->new(
                title => "Sandusky Path",
                width => 6,
                vars => [qw(a b c d e f)],
                functions => [qw(m2 m1 m0)],
                columns => [
                    {
                        minterms => \@col2,
                        dontcares => \@dontcares,
                    },
                    {
                        minterms => \@col1,
                        dontcares => \@dontcares,
                    },
                    {
                        minterms => \@col0,
                        dontcares => \@dontcares,
                    } ],
        );

=cut

sub push_minterm_columns
{
	my($idx, $val, @colrefs) = @_;

	my $ncols = $#colrefs;
	my $bit = 1 << $ncols;

	#
	# Slice the bits across the columns.
	#
	for my $j (0..$ncols)
	{
		push @{ $colrefs[$j] }, $idx if ($val & $bit);
		$bit >>= 1;
	}
}

sub push_maxterm_columns
{
	my($idx, $val, @colrefs) = @_;

	my $ncols = $#colrefs;
	my $bit = 1 << $ncols;

	#
	# Slice the bits across the columns.
	#
	for my $j (0..$ncols)
	{
		push @{ $colrefs[$j] }, $idx unless ($val & $bit);
		$bit >>= 1;
	}
}

=head3 var_column()

Return the list of terms that correspond to the set bits of a
variable's column.

    my @terms = var_column($width, $col);

For example, in a three-variable table

       x  y  z  | f
     -----------|--
  0  | 0  0  0  |
  1  | 0  0  1  |
  2  | 0  1  0  |
  3  | 0  1  1  |
  4  | 1  0  0  |
  5  | 1  0  1  |
  6  | 1  1  0  |
  7  | 1  1  1  |

column 2 (the x column) has terms (4, 5, 6, 7) set, while column 0
(the z column) has terms (1, 3, 5, 7) set.

=cut

sub var_column
{
	my($width, $col) = @_;

	croak "Column $col doesn't exist in a $width-column table." if ($col >= $width);

	#
	# A 'block' is a sequence of ones in the column.
	# 'blocklen' is the number of ones, blocks is the number of
	# those sequences.
	#
	# So in a set of four variable columns, column one's ones come
	# in eight sets of two ones.
	#
	my $blocklen = 1 << $col;
	my $blocks = 1 << ($width - $col - 1);
	my @terms;

	for my $n (0 .. $blocks - 1)
	{
		push @terms, map { (2 * $n + 1) * $blocklen + $_} (0 .. $blocklen - 1);
	}

	return @terms;
}

=head3 reverse_terms()

Reverses the list of terms by index. For example, within a four-bit range:

    $width = 4;                  # values range 0 .. 15.
    @terms = (1, 3, 6, 8, 13, 14);
    @terms = reverse_terms($width, \@terms);

The values in C<@terms> will become (14, 12, 9, 7, 2, 1).

=cut

sub reverse_terms
{
	my($width, $tref) = @_;
	my $last = (1 << $width) - 1;

	return map {$last - $_} @{ $tref };
}

=head3 rotate_terms()

Rotates the list of terms by index. For example, within a four-bit range:

    $width = 4;                  # values range 0 .. 15.
    $shift = 5;                  # term 0 becomes term 5, term 1 becomes term 6
    @terms = (1, 3, 7, 9, 13, 15);
    @terms = rotate_terms($width, \@terms, $shift);

The values in C<@terms> will become will be (6, 8, 12, 14, 2, 4),
with the last two list items rotated around to the beginning, having
been rotated past what C<$width> allows. A negative-valued shift rotates
the terms backward.

=cut

sub rotate_terms
{
	my($width, $tref, $shift) = @_;
	my $length = 1 << $width;

	$shift %= $length;

	$shift += $length while ($shift < 0);

	return @{ $tref } if ($shift == 0);

	return map {($shift + $_) % $length} @{ $tref };
}

=head3 shift_terms()

Shifts the list of terms by index. For example, within a four-bit range:

    $width = 4;                  # values range 0 .. 15.
    $shift = 5;                  # term 0 becomes term 5, term 1 becomes term 6
    @terms = (1, 3, 7, 9, 13, 15);
    @terms = shift_terms($width, \@terms, $shift);

The values in C<@terms> will become (6, 8, 12, 14), with the last
two list items dropped, having been shifted past what C<$width> allows.
A negative-valued shift shifts the terms downward.

=cut

sub shift_terms
{
	my($width, $tref, $shift) = @_;
	my $length = 1 << $width;

	if ($shift >= $length or $shift <= -$length)
	{
		return ();
	}
	elsif ($shift > 0)
	{
		return map {$shift + $_} grep {$_ < ($length - $shift)} @{ $tref };
	}
	else
	{
		return map {$shift + $_} grep {$_ >= -$shift} @{ $tref };
	}
}

=head1 SEE ALSO

L<Logic::TruthTable::Base81>

=head1 AUTHOR

John M. Gamble C<< <jgamble@cpan.org> >>

=cut

1;

__END__

