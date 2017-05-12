#_ Matrix _____________________________________________________________
# Test 3*3 matrices    
# philiprbrenan@yahoo.com, 2004, Perl License    
#______________________________________________________________________

use Math::Zap::Matrix identity=>i;
use Math::Zap::Vector;
use Test::Simple tests=>8;

my ($a, $b, $c, $v);

$a = matrix
 (8, 0, 0,
  0, 8, 0,
  0, 0, 8
 );

$b = matrix
 (4, 2, 0,
  2, 4, 2,
  0, 2, 4
 );

$c = matrix
 (4, 2, 1,
  2, 4, 2,
  1, 2, 4
 );

$v = vector(1,2,3);

ok($a/$a           == i());
ok($b/$b           == i());
ok($c/$c           == i());
ok(2/$a*$a/2       == i());
ok(($a+$b)/($a+$b) == i());
ok(($a-$c)/($a-$c) == i());
ok(-$a/-$a         == i());
ok(1/$a*($a*$v)    == $v);

