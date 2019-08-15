use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::Geometry;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Operation qw/isValid/;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "IsValidOp::isValid" => sub {
    my $c11 = Geo::Geos::Coordinate->new(1,2);
    my $c12 = Geo::Geos::Coordinate->new(5,2);
    my $g0 = $gf->createMultiPoint([$c11, $c12], 2);

    ok isValid($g0);
    ok isValid($c11);
};

done_testing;
