#_ Matrix _____________________________________________________________
# Test 2*2 matrices    
# philiprbrenan@yahoo.com, 2004, Perl License    
#______________________________________________________________________

use Math::Zap::Matrix2 identity=>i;
use Math::Zap::Vector2;
use Test::Simple tests=>8;

my ($a, $b, $c, $v);

$a = matrix2
 (8, 0,
  0, 8,
 );

$b = matrix2
 (4, 2,
  2, 4,
 );

$c = matrix2
 (2, 2,
  1, 2,
 );

$v = vector2(1,2);

ok($a/$a           == i());
ok($b/$b           == i());
ok($c/$c           == i());
ok(2/$a*$a/2       == i());
ok(($a+$b)/($a+$b) == i());
ok(($a-$c)/($a-$c) == i());
ok(-$a/-$a         == i());
ok(1/$a*($a*$v)    == $v);

