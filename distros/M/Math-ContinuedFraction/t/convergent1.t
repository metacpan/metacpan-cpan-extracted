#!perl

use Test::More tests => 12;

use Math::BigRat;
use Math::BigInt;
use Math::ContinuedFraction;

#
# Create sequence for pi with the first eleven terms.
# (It's irrational, and does not have a repeating sequence.)
#
my @pi_seq = (3, 7, 15, 1, 292, 1, 1);

my @conv = (
	{n => Math::BigInt->new(22), d => Math::BigInt->new(7)},
	{n => Math::BigInt->new(333), d => Math::BigInt->new(106)},
	{n => Math::BigInt->new(355), d => Math::BigInt->new(113)},
	{n => Math::BigInt->new(103993), d => Math::BigInt->new(33102)},
	{n => Math::BigInt->new(104348), d => Math::BigInt->new(33215)},
	{n => Math::BigInt->new(208341), d => Math::BigInt->new(66317)},
);

my $cf = Math::ContinuedFraction->new([@pi_seq]);

for my $j (1 .. scalar @conv)
{
	my($n, $d) = $cf->convergent($j);
	ok(($n == $conv[$j - 1]->{n} and $d == $conv[$j - 1]->{d}),
		"->convergent($j) returns (". $n . ", " . $d . ")");
}

for my $j (1 .. scalar @conv)
{
	my($r) = $cf->brconvergent($j);
	my($n, $d) = $r->parts();
	ok(($n == $conv[$j - 1]->{n} and $d == $conv[$j - 1]->{d}),
		"->brconvergent($j) returns (". $n . ", " . $d . ")");
}

exit(0);
