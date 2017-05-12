#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::More tests => 1;

($i, $x, $f, $one, $zero) = symbols(qw(i x 5 1 0));

    $x  = ($one+sqrt($f)) / 4; 
    $a  = ($x+$i*sqrt(1-$x*$x))**3;
    $b  = ($x+$i*sqrt(1-$x*$x))**2;
    $c  = $a-$b;
    $d  = $c->im;
ok( $d == $zero);

