#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: expression substitution for a variable.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>2;

my ($x, $y) = symbols(qw(x y));
 
my $e  = 1+$x+$x**2/2+$x**3/6+$x**4/24+$x**5/120;

ok(  $e->sub(x=>$y**2, z=>2)  <=> '$y**2+1/2*$y**4+1/6*$y**6+1/24*$y**8+1/120*$y**10+1'  );
ok(  $e->sub(x=>1)            <=>  '163/60');          

