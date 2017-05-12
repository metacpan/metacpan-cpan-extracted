#_ Vector _____________________________________________________________
# Test 3d vectors    
# philiprbrenan@yahoo.com, 2004, Perl License    
#______________________________________________________________________

use Math::Zap::Vector vector=>'v', units=>'u';
use Test::Simple tests=>7;

my ($x, $y, $z) = u();

ok(!$x                            == 1);
ok(2*$x+3*$y+4*$z                 == v( 2,  3,   4));
ok(-$x-$y-$z                      == v(-1, -1,  -1));
ok((2*$x+3*$y+4*$z) + (-$x-$y-$z) == v( 1,  2,   3));
ok((2*$x+3*$y+4*$z) * (-$x-$y-$z) == -9);  
ok($x*2                           == v( 2,  0,   0));
ok($y/2                           == v( 0,  0.5, 0));

