#!perl -w
#______________________________________________________________________
# Symbolic algebra: examples: simplify.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests=>2;
 
my ($x) = symbols(qw(x));
 
my $y  = (($x**8 - 1)/($x-1))->simplify();  # Simplify method 
my $z +=  ($x**8 - 1)/($x-1);               # Simplify via +=

ok( "$y" eq '$x+$x**2+$x**3+$x**4+$x**5+$x**6+$x**7+1' );
ok( "$z" eq '$x+$x**2+$x**3+$x**4+$x**5+$x**6+$x**7+1' );

