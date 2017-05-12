#!perl

use Test::Simple tests => 4;

use Math::BigRat;
use Math::BigInt;
use Math::ContinuedFraction;

#
# Create phi.
#
my $cf = Math::ContinuedFraction->new([1, [1]]);

my($n, $d) = $cf->convergent(2);
ok(($n == 2 and $d == 1), "->convergent(2) returns (". $n . ", " . $d . ")");
($n, $d) = $cf->convergent(3);
ok(($n == 3 and $d == 2), "->convergent(3) returns (". $n . ", " . $d . ")");
($n, $d) = $cf->convergent(4);
ok(($n == 5 and $d == 3), "->convergent(4) returns (". $n . ", " . $d . ")");
($n, $d) = $cf->convergent(5);
ok(($n == 8 and $d == 5), "->convergent(5) returns (". $n . ", " . $d . ")");

exit(0);
