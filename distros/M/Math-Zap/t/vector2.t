#_ Vector _____________________________________________________________
# Test 2d vectors    
# philiprbrenan@yahoo.com, 2004, Perl License    
#______________________________________________________________________

use Math::Zap::Vector2 vector2=>v, units=>u;
use Test::Simple tests=>7;

my ($x, $y) = u();

ok(!$x                    == 1);
ok(2*$x+3*$y              == v( 2,  3));
ok(-$x-$y                 == v(-1, -1));
ok((2*$x+3*$y) + (-$x-$y) == v( 1,  2));
ok((2*$x+3*$y) * (-$x-$y) == -5);  
ok($x*2                   == v( 2,  0));
ok($y/2                   == v( 0,  0.5));

