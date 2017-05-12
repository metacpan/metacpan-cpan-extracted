#_ Vector _____________________________________________________________
# Test 2d lines    
# philiprbrenan@yahoo.com, 2004, Perl License    
#______________________________________________________________________

use Math::Zap::Line2;
use Math::Zap::Vector2;
use Test::Simple tests=>12;

my $x = vector2(1,0);
my $y = vector2(0,1);
my $c = vector2(0,0);

my $a = line2( -$x,  +$x);
my $b = line2( -$y,  +$y);
my $B = line2(3*$y, 4*$y);

ok($a->intersect($b) == $c);
ok($b->intersect($a) == $c);
ok($a->intersectWithin($b) == 1);
ok($a->intersectWithin($B) == 0);
ok($b->intersectWithin($a) == 1);
ok($B->intersectWithin($a) == 1);
ok($a->parallel($b) == 0);
ok($B->parallel($b) == 1);
ok(!$b->intersectWithin($B), 'Parallel intersection');
ok( line2(-$x,       $x)->crossOver(line2(-$y,       $y)), 'Crosses 1');
ok(!line2(-$x,       $x)->crossOver(line2( $y * 0.5, $y)), 'Crosses 2');
ok(!line2( $x * 0.5, $x)->crossOver(line2( $y * 0.5, $y)), 'Crosses 3');

