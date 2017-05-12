#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: simplification.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>3;

my ($x, $y) = symbols(qw(x y));

ok(  ($x**2-$y**2)/($x-$y)  ==  $x+$y  );
ok(  ($x**2-$y**2)/($x-$y)  !=  $x-$y  );
ok(  ($x**2-$y**2)/($x-$y) <=> '$x+$y' );


