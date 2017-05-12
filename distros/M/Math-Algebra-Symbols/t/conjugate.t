#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: dot operator.  Note the low priority
# of the ^ operator.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>3;

my ($x, $y, $i) = symbols(qw(x y i));

ok(  ~($x+$i*$y)  ==  $x-$i*$y  );
ok(  ~($x-$i*$y)  ==  $x+$i*$y  );
ok(  (($x+$i*$y)^($x-$i*$y)) <=> '$x**2-$y**2' );

