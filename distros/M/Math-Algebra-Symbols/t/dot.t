#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: dot operator.  Note the low priority
# of the ^ operator.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>3;

my ($a, $b, $i) = symbols(qw(a b i));

ok(  (($a+$i*$b)^($a-$i*$b))  ==  $a**2-$b**2  );
ok(  (($a+$i*$b)^($a-$i*$b))  !=  $a**2+$b**2  );
ok(  (($a+$i*$b)^($a-$i*$b)) <=> '$a**2-$b**2' );

