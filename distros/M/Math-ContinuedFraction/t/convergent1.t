#!perl

use Test::Simple tests => 5;

use Math::BigRat;
use Math::BigInt;
use Math::ContinuedFraction;

#
# Create sequence for pi with the first eleven terms.
# (It's irrational, and does not have a repeating sequence.)
#
my $cf = Math::ContinuedFraction->new([3, 7, 15, 1, 292, 1, 1, 1, 21, 3, 1]);

my($n, $d) = $cf->convergent(1);
ok(($n == 22 and $d == 7), "->convergent(2) returns (". $n . ", " . $d . ")");
($n, $d) = $cf->convergent(2);
ok(($n == 333 and $d == 106), "->convergent(2) returns (". $n . ", " . $d . ")");
($n, $d) = $cf->convergent(3);
ok(($n == 355 and $d == 113), "->convergent(3) returns (". $n . ", " . $d . ")");
($n, $d) = $cf->convergent(4);
ok(($n == 103993 and $d == 33102), "->convergent(4) returns (". $n . ", " . $d . ")");
($n, $d) = $cf->convergent(5);
ok(($n == 104348 and $d == 33215), "->convergent(5) returns (". $n . ", " . $d . ")");

exit(0);
