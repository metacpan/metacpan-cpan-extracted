# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 13-divide.t'
use 5.010001;
use Test::More tests => 5;

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
# Groups of four: numerator, divisor, quotient, remainder.
#
my @case0 = (
	[
		[90, -53, 7, -70, 49, -7, -20, 4],
		[9, -8, 4],
		[10, 3, -1, -10, -3, 1],
		[0, 0]
	],
	[
		[1, 0, 0, 0, 34, 0, 0, 0, 1],
		[1, 4, 8, 4, 1],
		[1, -4, 8, -4, 1],
		[0, 0, 0, 0]
	],
	[
		[1, 6, 15, 32, 58, 88, 116, 160, 165, 138, 133],
		[1, 3, 5, 7, 11, 13, 17, 19],
		[1, 3, 1, 7],
		[0, 0, 0, 0, 0, 0, 0]
	],
	[
		[4, 12, 9, 3],
		[1, 3, 3, 1],
		[3],
		[1, 3, 0]
	],
	[
		[4, 13, 4, -9, 6],
		[1, 2],
		[4, 5, -6, 3],
		[0]
	]
);

foreach my $cref (@case0)
{
	my($p_ref, $d_ref, $q_ref, $r_ref) = @$cref;

	my($q, $r) = pl_div($p_ref, $d_ref);

	my @polynomial = @$p_ref;
	my @divisor = @$d_ref;
	my @quotient = @$q;
	my @remainder = @$r;

	ok((polycmp($q_ref, $q) == 0 and polycmp($r_ref, $r) == 0),
		" [ " . join(", ", @polynomial) . " ] /" .
		" [ " . join(", ", @divisor) . " ] returns\n" .
		" [ " . join(", ", @quotient) . " ] and" .
		" [ " . join(", ", @remainder) . " ].\n"
	);
}

1;
