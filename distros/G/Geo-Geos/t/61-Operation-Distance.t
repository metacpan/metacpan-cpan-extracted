use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::Geometry;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Operation qw/distance nearestPoints closestPoints/;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "DistanceOp" => sub {
    my $c11 = Geo::Geos::Coordinate->new(1,2);
    my $c12 = Geo::Geos::Coordinate->new(5,2);
    my $g0 = $gf->createMultiPoint([$c11, $c12], 2);

    my $c21 = Geo::Geos::Coordinate->new(1,3);
    my $c22 = Geo::Geos::Coordinate->new(5,3);
    my $g1 = $gf->createMultiPoint([$c21, $c21], 2);

    subtest "distance" => sub {
        is distance($g0, $g1), 1;
    };

    subtest "nearestPoints" => sub {
        my $p = nearestPoints($g0, $g1);
        is_deeply $p, [$c11, $c21];
    };

    subtest "closestPoints" => sub {
        my $p = closestPoints($g0, $g1);
        is_deeply $p, [$c11, $c21];
    };
};

done_testing;
