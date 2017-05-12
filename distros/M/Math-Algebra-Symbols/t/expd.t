#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: exp.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>2;

my ($x, $i) = symbols(qw(x i));

ok(   exp($x)->d($x)  ==   exp($x)  );
ok(   exp($x)->d($x) <=>  'exp($x)' );


