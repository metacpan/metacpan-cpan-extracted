#_ Triangle ___________________________________________________________
# Test 2d triangles    
# philiprbrenan@yahoo.com, 2004, Perl License    
#______________________________________________________________________

use Math::Zap::Triangle2;
use Math::Zap::Vector2;
use Test::Simple tests=>27;
 
$a = triangle2
 (vector2(0, 0), 
  vector2(2, 0), 
  vector2(0, 2),
 );
 
$b = triangle2
 (vector2( 0,  0), 
  vector2( 4,  0), 
  vector2( 0,  4),
 );
 
$c = triangle2
 (vector2( 0,  0), 
  vector2(-4,  0), 
  vector2( 0, -4),
 );
 
$d = $b - vector2(1,1);
$e = $c + vector2(1,1);

#print "a=$a\nb=$b\nc=$c\nd=$d\ne=$e\n";

ok($a->containsPoint(vector2( 1,  1)));
ok($a->containsPoint(vector2( 1,  1)));
ok($b->containsPoint(vector2( 2,  0)));
ok($b->containsPoint(vector2( 1,  0)));
ok($c->containsPoint(vector2(-1,  0)));
ok($c->containsPoint(vector2(-2,  0)));
ok($d->containsPoint(vector2( 1, -1)));

ok(!$a->containsPoint(vector2( 9,  1)));
ok(!$a->containsPoint(vector2( 1,  9)));
ok(!$b->containsPoint(vector2( 2,  9)));
ok(!$b->containsPoint(vector2( 9,  0)));
ok(!$c->containsPoint(vector2(-9,  0)));
ok(!$c->containsPoint(vector2(-2,  9)));
ok(!$d->containsPoint(vector2( 9, -1)));

ok( $a->containsPoint(vector2(0.5, 0.5)));
ok(!$a->containsPoint(vector2( -1,  -1)));

ok(vector2(1,2)->rightAngle == vector2(-2, 1));
ok(vector2(1,0)->rightAngle == vector2( 0, 1));

ok($a->area == 2);
ok($c->area == 8);

eval { triangle2(vector2(0, 0), vector2(3, -6), vector2(-3, 6))};
ok($@ =~ /^Narrow triangle2/, 'Narrow triangle');

$t = triangle2(vector2(0,0),vector2(0,10),vector2( 10,0));
$T = triangle2(vector2(0,0),vector2(0,10),vector2(-10,10))+vector2(5, -2);
@p = $t->ring($T);
#print "$_\n" for(@p);
ok($p[0] == vector2(0, 8), 'Ring 0');
ok($p[1] == vector2(2, 8), 'Ring 1');
ok($p[2] == vector2(5, 5), 'Ring 2');
ok($p[3] == vector2(5, 0), 'Ring 3');
ok($p[4] == vector2(3, 0), 'Ring 4');
ok($p[5] == vector2(0, 3), 'Ring 5');
