#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra: Hyperbola.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::More tests => 1;
no warnings qw(void);

($x, $y, $i) = symbols(qw(x y i));

# Find focii of hyperbola y=1/x

# Assume by symmetry the focii are on
'   the line y=x:                       ',   $f1 = $x + $i * $x,
'   and equidistant from the origin:    ',   $f2 = -$f1,
'   Choose a convenient point on y=1/x: ',   $a = 1+$i,
'    and another point:                 ',   $b = $y+$i/$y,

'  Distances from focii                 ',
'    From first point:                  ',   $A = abs($a - $f2) - abs($a - $f1),  
'    From second point:                 ',   $B = abs($b - $f2) + abs($b - $f1),
'  Solve for difference in distances    ',   ok( (($A-$B) > $x) == sqrt(symbols('2')));

