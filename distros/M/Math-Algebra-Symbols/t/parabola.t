#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra: Parabola.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::More tests => 2;
no warnings qw(void);

($x, $i) = symbols(qw(x i));

# Parabola: Focussing to infinity

' From focus to locus:    ',      $a = $x + $i * $x**2 - $i/4,
' Vertical of same length:',      $b = $i * abs($a),
' Tangent vector to locus:',      $d =  1 + 2*$x*$i,
' Compare angles via dot: ', ok( ($a ^ $d) == ($b ^ $d), 'Focusses to infinity');


# Distance from focus to locus to directrix at y = 1/4

' From focus to locus:            ',     $a = $x + $i * $x**2 - $i/4,
' From focus to locus squared:    ',     $A = $a^$a,
' From locus to directrix squared:',     $B = ($x**2 + '1/4')**2, 

' Equal lengths',  ok ($A  == $B, 'Distance from focus to locus equals distance from locus to directrix');

