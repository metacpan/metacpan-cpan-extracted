#!perl

use Math::BigRat;
use Math::BigInt;
use Math::ContinuedFraction;

use Test::More tests => 11;

my $phi_seq = [1, [1]];

my @conv = (
	{n => 1, d => 0},
	{n => 2, d => 1},
	{n => 3, d => 2},
	{n => 5, d => 3},
	{n => 8, d => 5},
	{n => 13, d => 8},
	{n => 21, d => 13},
	{n => 34, d => 21},
	{n => 55, d => 34},
	{n => 89, d => 55},
	{n => 144, d => 89},
);

my $cf = Math::ContinuedFraction->new($phi_seq);

for my $j (0 .. $#conv)
{
	my($n, $d) = $cf->convergent($j + 1);
	ok(($n == $conv[$j]->{n} and $d == $conv[$j]->{d}),
		"->convergent(" . $j + 1 . ") returns (". $n . ", " . $d . ")");
}

exit(0);
