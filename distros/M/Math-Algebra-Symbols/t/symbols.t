#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols hyper=>1;
use Test::Simple tests=>5;

($n, $x, $y) = symbols(qw(n x y));

$a     += ($x**8 - 1)/($x-1);
$b     +=  sin($x)**2 + cos($x)**2; 
$c     += (sin($n*$x) + cos($n*$x))->d->d->d->d / (sin($n*$x)+cos($n*$x));
$d      =  tanh($x+$y) == (tanh($x)+tanh($y))/(1+tanh($x)*tanh($y));
($e,$f) =  @{($x**2 eq 5*$x-6) > $x};

print "$a\n$b\n$c\n$d\n$e,$f\n";

ok("$a"    eq '$x+$x**2+$x**3+$x**4+$x**5+$x**6+$x**7+1');
ok("$b"    eq '1'); 
ok("$c"    eq '$n**4'); 
ok("$d"    eq '1'); 
ok("$e,$f" eq '2,3');

