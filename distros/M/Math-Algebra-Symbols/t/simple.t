#!perl -w -I..
#______________________________________________________________________
# Symbolic algebra: simple tests.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::More tests => 34;

($a, $b, $x, $i, $zero, $one, $two) = symbols(qw(2 3 x i 0 1 2));

ok(  symbols(0)          == $zero);
ok(  symbols(0)          != $one); 
ok(  symbols(1)          == $one);
ok(  symbols(1)          != $zero);
ok(  $a                  == $two);
ok(  $b                  == 3);
ok(  $a+$a               == 4);
ok(  $a+$b               == 5);
ok(  $a+$b+$a+$b         == 10);
ok(  $a+1                == 3);
ok(  $a+2                == 4);
ok(  $b-1                == 2);
ok(  $b-2                == 1);
ok(  $b-9                == -6);
ok(  $a/2                == $one);
ok(  $a/4                == '1/2');
ok(  $a*2/2              == $two);
ok(  $a*2/4              == $one);
ok(  $a**2               == 4);
ok(  $a**10              == 1024);
ok(  sqrt($a**2)         == $a);
ok(  sqrt(symbols(-1))   == 'i');
ok(  sqrt(symbols(4))    == 2);
ok(  symbols('1/2') + '1/3' + '1/4' - '1/12' == 1);
ok(  sqrt(symbols('-1')) == $i);
ok(  symbols('x')        == $x);
ok(  symbols('2*x**2')   == 2*$x**2);
ok(  $a+$a               == 2*$a);
ok(  $a+$a+$a            == 3*$a);
ok(  $a-$a               == $zero);
ok(  $a-$a-$a            == -$a);
ok(  $a*$b*$a*$b         == $a**2*$b**2);
ok( ($b/$a)**2           == $b**2/$a**2);
ok(  $a**128             == '340282366920938463463374607431768211456');

