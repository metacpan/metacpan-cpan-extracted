=head1 NAME

Logic::TruthTable::Convert81 - provide Base81 encoding to Logic::TruthTable

=cut

package Logic::TruthTable::Convert81;

use strict;
use warnings;
use 5.016001;

use Carp;
use Exporter;
use Convert::Base81 qw(b3_pack81 b3_unpack81 base81_check);

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	all => [ qw(
		terms_to_base81
		terms_from_base81
	) ],
);

our @EXPORT_OK = (
	@{$EXPORT_TAGS{all}},
);

our $VERSION = 1.00;

=head1 DESCRIPTION

This module provides Base81 encoding of the truth table's columns
when saving the table in JSON format.

=head2 FUNCTIONS

=head3 terms_to_base81

Take the terms of a truth table's column and pack it into a Base81 string.

    $col = $tt->fncolumn("f1");
    $b81str = terms_to_base81($tt->width, $col->has_minterms,
            $col->has_minterms? $col->minterms: $col->maxterms,
            $col->dontcares);

=cut

sub terms_to_base81
{
	my($width, $isminterms, $termref, $dontcaresref)= @_;
	my ($dfltbit, $setbit, $dcbit) = ($isminterms)? qw(0 1 -): qw(1 0 -);

	#
	# Set up the list of trits to be packed into Base81 code.
	#
	my @blist = ($dfltbit) x (1 << $width);
	map {$blist[$_] = $setbit} @{$termref};
	map {$blist[$_] = $dcbit} (@{$dontcaresref});

	return b3_pack81("01-", \@blist);
}

=head3 terms_from_base81

Retrieve arrayrefs of the minterms, maxterms, and don't-cares of a
truth table's column from a Base81 string.

    (@min_max_dc) = terms_from_base81($width, $b81str);

=cut

sub terms_from_base81
{
	my($width, $base81str) = @_;

	#
	# Does the string we read in create a column of the correct length?
	# (With the edge case exception width == 1, of course.)
	#
	unless (length($base81str) == (1 << ($width - 2)) or
	    (length($base81str) == 1 and $width == 1))
	{
		return (undef, undef, undef);
	}

	my @char81 = split(//, $base81str);

	if (my $c_idx = base81_check($base81str) >= 0)
	{
		carp "Incorrect character '" .  $char81[$c_idx] .
			"' at position " .  $c_idx .
			"; cannot create columnlist";
		return (undef, undef, undef);
	}

	my(@maxterms, @minterms, @dontcares);
	my @clist = b3_unpack81("01-", $base81str);

	for my $t (0 .. $#clist)
	{
		my $x = $clist[$t];
		if ($x eq '1')
		{
			push @minterms, $t;
		}
		elsif ($x eq '0')
		{
			push @maxterms, $t;
		}
		else
		{
			push @dontcares, $t;
		}
	}

	return (\@minterms, \@maxterms, \@dontcares);
}

=head1 SEE ALSO

L<Convert::Base81>

L<Logic::TruthTable::Util>

=head1 AUTHOR

John M. Gamble C<< <jgamble@cpan.org> >>

=cut

1;

__END__

