#_ Rectangle __________________________________________________________
# Test 3d rectangles          
# philiprbrenan@yahoo.com, 2004, Perl License    
#______________________________________________________________________

use Math::Zap::Rectangle;
use Math::Zap::Vector;
use Test::Simple tests=>3;

my ($a, $b, $c, $d) =
 (vector(0,    0, +1),
  vector(0, -1.9, -1),
  vector(0, -2.0, -1),
  vector(0, -2.1, -1)
 );

my $r = rectangle
 (vector(-1,-1, 0),
  vector( 2, 0, 0),
  vector( 0, 2, 0)
 );

ok($r->intersects($a, $b) == 1);
ok($r->intersects($a, $c) == 1);
ok($r->intersects($a, $d) == 0);

