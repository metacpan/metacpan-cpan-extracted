use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::Geometry;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Operation qw/isSequenced sequence/;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "LineSequencer" => sub {
    my $c11 = Geo::Geos::Coordinate->new(1,2);
    my $c12 = Geo::Geos::Coordinate->new(5,2);
    my $ls1 = $gf->createLineString([$c11, $c12], 2);
    ok isSequenced($ls1);
    is sequence($ls1), $ls1;
};

done_testing;
