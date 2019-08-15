use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::Geometry;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Operation;
use Geo::Geos::Operation qw/relate/;
use Geo::Geos::IntersectionMatrix;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "RelateOp" => sub {
    my $c11 = Geo::Geos::Coordinate->new(1,2);
    my $c12 = Geo::Geos::Coordinate->new(5,2);
    my $g0 = $gf->createMultiPoint([$c11, $c12], 2);

    my $c21 = Geo::Geos::Coordinate->new(1,3);
    my $c22 = Geo::Geos::Coordinate->new(5,3);
    my $g1 = $gf->createMultiPoint([$c21, $c21], 2);

    subtest "relate" => sub {
        my $im = relate($g0, $g1);
        ok $im;
        is "$im", 'FF0FFF0F2';
    };

    subtest "relate with BoundaryNodeRule" => sub {
        my $im = relate($g0, $g1, TYPE_BOUNDARY_OGCSFS);
        ok $im;
        is "$im", 'FF0FFF0F2';
    };
};

done_testing;
