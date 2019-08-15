use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Prep::GeometryFactory;

my $gf = Geo::Geos::GeometryFactory::create();
my $c1 = Geo::Geos::Coordinate->new(1,2);
my $c2 = Geo::Geos::Coordinate->new(5,2);
my $c3 = Geo::Geos::Coordinate->new(5,0);
my $c4 = Geo::Geos::Coordinate->new(1,0);

my $lr1 = $gf->createLinearRing([$c1, $c2, $c3, $c4, $c1], 2);
my $p1 = $gf->createPolygon($lr1);

my $cx1 = Geo::Geos::Coordinate->new(1.5,1.5);
my $cx2 = Geo::Geos::Coordinate->new(4,1.5);
my $cx3 = Geo::Geos::Coordinate->new(4,0.5);
my $cx4 = Geo::Geos::Coordinate->new(1.5,0.5);
my $lr2 = $gf->createLinearRing([$cx1, $cx2, $cx3, $cx4, $cx1], 2);

my $p2 = $gf->createPolygon($lr2);

my ($pp1, $pp2) =  map { Geo::Geos::Prep::GeometryFactory::prepare($_) } ($p1, $p2);
ok $pp1;
ok $pp2;

ok $pp1->contains($p2);
ok $pp1->containsProperly($p2);
ok !$pp1->coveredBy($p2);
ok $pp1->covers($p2);
ok !$pp1->crosses($p2);
ok !$pp1->disjoint($p2);
ok $pp1->intersects($p2);
ok !$pp1->overlaps($p2);
ok !$pp1->touches($p2);
ok !$pp1->within($p2);

is $pp1->toString, $p1->toString;
is "$pp1", 'POLYGON ((1.0000000000000000 2.0000000000000000, 5.0000000000000000 2.0000000000000000, 5.0000000000000000 0.0000000000000000, 1.0000000000000000 0.0000000000000000, 1.0000000000000000 2.0000000000000000))';

done_testing;
