use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::Geometry;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Operation;
use Geo::Geos::Operation qw/overlayOp/;


my $gf = Geo::Geos::GeometryFactory::create();

subtest "OverlayOp::overlayOp" => sub {
    my $c11 = Geo::Geos::Coordinate->new(1,2);
    my $c12 = Geo::Geos::Coordinate->new(5,2);
    my $g0 = $gf->createMultiPoint([$c11, $c12], 2);

    my $c21 = Geo::Geos::Coordinate->new(1,3);
    my $c22 = Geo::Geos::Coordinate->new(5,3);
    my $g1 = $gf->createMultiPoint([$c21, $c21], 2);

    my $g = overlayOp($g0, $g1, TYPE_OP_INTERSECTION);
    ok $g;
    like( $g->toString, qr/GEOMETRYCOLLECTION EMPTY/);
};

done_testing;
