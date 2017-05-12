#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: simplification.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>3;

my ($x) = symbols(qw(x));

ok(  sin($x)**2 + cos($x)**2  ==  1  );
ok(  sin($x)**2 + cos($x)**2  !=  0  );
ok(  sin($x)**2 + cos($x)**2 <=> '1' );


