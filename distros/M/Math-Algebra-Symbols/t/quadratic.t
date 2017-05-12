#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra: quadratic equation.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Test::More tests => 1;
use Math::Algebra::Symbols;

($a, $b, $c, $x, $y) = symbols(qw(a b c x y));

$p = $a*$x**2 + $b*$x + $c;       # The polynomial in question
$q = sqrt($y)/sqrt($a) - $b/2/$a; # Proposed Substitution
$y = $p->sub(x=>$q);              # Perform substitution

$z = $y->solve(qw(y a b c));      # Solve for y - assumes substitution reduced the complexity of the polynomail by eliminating a term
$x = $q->sub(y=>$z);              # Substitute back to get result in terms of x  

print "x=$x\n";                   # Proposed solution

ok( $x == (-$b+sqrt($b*$b-4*$a*$c))/(2*$a), 'Quadratic solution');

