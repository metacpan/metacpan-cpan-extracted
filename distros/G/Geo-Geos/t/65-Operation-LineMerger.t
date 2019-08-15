use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::Geometry;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Operation qw/mergeLines/;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "LineMerger" => sub {
    my $c11 = Geo::Geos::Coordinate->new(1,2);
    my $c12 = Geo::Geos::Coordinate->new(5,2);
    my $c21 = Geo::Geos::Coordinate->new(5,2);
    my $c22 = Geo::Geos::Coordinate->new(7,2);

    my $ls1 = $gf->createLineString([$c11, $c12], 2);
    my $ls2 = $gf->createLineString([$c21, $c22], 2);
    my $merged = mergeLines([$ls1, $ls2]);
    ok $merged;
    is scalar(@$merged), 1;
    is $merged->[0]->toString, 'LINESTRING (1.0000000000000000 2.0000000000000000, 5.0000000000000000 2.0000000000000000, 7.0000000000000000 2.0000000000000000)';
};

done_testing;
