use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Algorithm::MinimumDiameter;

subtest "MinimumDiameter" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(5,0);
    my $c4 = Geo::Geos::Coordinate->new(1,0);
    my $gf = Geo::Geos::GeometryFactory::create();

    my $lr = $gf->createLinearRing([$c1, $c2, $c3, $c4, $c1], 2);
    my $md1 = Geo::Geos::Algorithm::MinimumDiameter->new($lr);
    ok $md1;

    my $md2 = Geo::Geos::Algorithm::MinimumDiameter->new($lr, 1);
    ok $md2;

    is $md2->getLength, 2;
    is $md2->getWidthCoordinate, $c4;
    is $md2->getSupportingSegment, $gf->createLineString([$c1, $c2], 2);
    is $md2->getDiameter, 'LINESTRING (1.0000000000000000 2.0000000000000000, 1.0000000000000000 0.0000000000000000)';
    like $md2->getMinimumRectangle, qr/POLYGON/;

    my $g1 = Geo::Geos::Algorithm::MinimumDiameter::getMinimumDiameter($lr);
    is $g1, $md2->getDiameter;

    my $g2 = Geo::Geos::Algorithm::MinimumDiameter::getMinimumRectangle($lr);
    is $g2, $md2->getMinimumRectangle;
};

done_testing;
