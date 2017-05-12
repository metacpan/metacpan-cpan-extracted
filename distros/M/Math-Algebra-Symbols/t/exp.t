#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::More tests => 9;

($x, $zero, $one, $i, $pi) = symbols(qw(x 0 1 i pi));
           
ok(  exp($zero)          ==  $one);
ok(  exp($i*$pi/2)       ==  $i);
ok(  exp($i*$pi)         == -$one);
ok(  exp(3*$i*$pi/2)     == -$i);
ok(  exp(4*$i*$pi/2)     ==  $one);
ok(  exp($i*$pi)         == -1);
ok(  $i*exp(3*$i*$pi/2)  == 1);

ok(  exp($x)*exp($i*$x)*exp($x)*exp(-$i*$x)-exp(2*$x) == 0);

ok(  1+$one+'1/2'*$one**2+'1/6'*$one**3+'1/24'*$one**4+'1/120'*$one**5+
    '1/720'*$one**6+'1/5040'*$one**7+'1/40320'*$one**8
     == '109601/40320');

