# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 14-derivative.t'
use 5.010001;
use Test::More tests => 16;

use Math::Utils qw(:polynomial);
use strict;
use warnings;

#
# returns 0 (equal) or 1 (not equal). There's no -1 value, unlike other cmp functions.
#
sub polycmp
{
	my($p_ref1, $p_ref2) = @_;

	my @polynomial1 = @$p_ref1;
	my @polynomial2 = @$p_ref2;

	return 1 if (scalar @polynomial1 != scalar @polynomial2);

	foreach my $c1 (@polynomial1)
	{
		my $c2 = shift @polynomial2;
		return 1 if ($c1 != $c2);
	}

	return 0;
}


#
# Pairs of polynomnials and their derivatives.
#
my @case = (
	[1], [],
	[3, 5], [5],
	[1, 24, 32], [24, 64],
	[289, 4, 3, 2, 1], [4, 6, 6, 4],
	[-1, -3, 0, 0, 0, 1], [-3, 0, 0, 0, 5],
	[90, -53, 7, -70, 49, -7, -20, 4], [-53, 14, -210, 196, -35, -120, 28],
	[1, 0, 0, 0, 34, 0, 0, 0, 1], [0, 0, 0, 136, 0, 0, 0, 8],
	[4, 12, 9, 3], [12, 18, 9],
);

#
# Peel off two items per loop.
#
while (@case)
{
	my $p_ref = shift @case;
	my $d_ref = shift @case;
	my @polynomial = @$p_ref;
	my $constant = $polynomial[0];

	my $derivative = pl_derivative(\@polynomial);

	ok((polycmp($d_ref, $derivative) == 0),
		" f() = [ " . join(", ", @polynomial) . " ]\n" .
		" f'() = [ " . join(", ", @{$derivative}) . " ].\n"
	);

	my $antiderivative = pl_antiderivative($derivative);
	$antiderivative->[0] = $constant;

	ok((polycmp($p_ref, $antiderivative) == 0),
		" f() = [ " . join(", ", @{$derivative}) . " ]\n" .
		" integral f() = [ " . join(", ", @{$antiderivative}) . " ].\n"
	);
}

1;

