#!perl -w
#______________________________________________________________________
# Symbolic algebra.
# PhilipRBrenan@yahoo.com, 2004, Perl License.
#______________________________________________________________________

use Math::Algebra::Symbols;
use Test::Simple tests => 21;

($a, $b, $x, $y, $i, $one) = symbols(qw(a b x y i 1));

ok(  ($i ^ 1)         == 0);
ok(  ($i ^ $i)        == 1);
ok(  $i x 1           == 1);
ok(  $i x $i          == 0);
ok(  $one x 1         == 0);
ok(  !$i              == $i);
ok(  abs $i           == 1);
ok(  re  $i           == 0);
ok(  im  $i           == 1);
ok(  re  $one         == 1);
ok(  im  $one         == 0);
ok(  ($i+1) x ($i-1)  == 2);
ok(  (1+$i  ^ -1+$i)  == 0);

ok(  ~($x+$y)         ==  ~$x + ~$y);
ok(  ~($x*$y)         ==  ~$x * ~$y);
ok(  ~($x**2)         == (~$x)** 2);

ok(  abs($x+$y*$i)    == sqrt($x**2+$y**2));
ok(  !($x+$y*$i)      == ($x+$y*$i) / sqrt($x**2+$y**2));
ok(  abs(!($x+$y*$i)) == sqrt($x**2/($x**2+$y**2)+$y**2/($x**2+$y**2)));

ok(  abs(($a+$i*sqrt(1-$a*$a))*($b+$i*sqrt(1-$b*$b))) == 1);
ok(  abs($a+$i*$b)*abs($x+$i*$y) == abs(($a+$i*$b)*($x+$i*$y)));

