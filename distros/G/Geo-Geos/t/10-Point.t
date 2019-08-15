use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::PrecisionModel qw/TYPE_FLOATING_SINGLE/;
use Geo::Geos::Geometry qw/TYPE_GEOS_POINT/;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Dimension qw/TYPE_DONTCARE TYPE_True TYPE_False TYPE_P TYPE_L TYPE_A/;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "empty point" => sub {
    my $p = $gf->createPoint;
    ok $p->isEmpty();
    ok $p->isSimple();
    is $p->getNumPoints, 0;
    is $p->getDimension, TYPE_P;
    is $p->getCoordinateDimension, 3;
    is $p->getBoundaryDimension, -1;
    is $p->getCoordinate, undef;
    is $p->getGeometryType, "Point";
    is $p->getGeometryTypeId, TYPE_GEOS_POINT;
    ok $p->isa('Geo::Geos::Puntal');
};

subtest "point from coordinate" => sub {
    my $c = Geo::Geos::Coordinate->new(1,2);
    my $p = $gf->createPoint($c);
    ok !$p->isEmpty();
    ok $p->isSimple();
    is $p->getNumPoints, 1;
    is $p->getDimension, TYPE_P;
    is $p->getCoordinateDimension, 2;
    is $p->getBoundaryDimension, -1;
    is $p->getCoordinate, $c;
    is $p->getX, 1;
    is $p->getY, 2;
    is $p->getNumGeometries, 1;

    $p->normalize();
    is $p->getCoordinate, $c;
};

subtest "point from coordinate sequecne" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $p1 = $gf->createPoint([$c1], 2);
    ok !$p1->isEmpty();
    is $p1->getX, 1;
    is $p1->getY, 2;

    my $c2 = Geo::Geos::Coordinate->new(1,2,3);
    my $p2 = $gf->createPoint([$c2], 2);
    is $p2->getX, 1;
    is $p2->getY, 2;
    is $p2->getY, 2;
};


subtest "geometry methods" => sub {
    my $c = Geo::Geos::Coordinate->new(1,2);
    my $p = $gf->createPoint($c);
    is $p->toString(), "POINT (1.0000000000000000 2.0000000000000000)";
    is $p->getNumGeometries, 1;

    my $g1 = $p->reverse;
    is $g1->toString, "POINT (1.0000000000000000 2.0000000000000000)";
    is "$g1", "$p";

    my $g2 = $p->getBoundary;
    is $g2->toString, "GEOMETRYCOLLECTION EMPTY";

    ok $p->equalsExact($g1);
    ok $p->equalsExact($g1, 0);
    ok $p->equalsExact($g1, 1);

    my $p2 = $p->clone;
    is $p, $p2;

    my $p3 = $p->getGeometryN(0);
    is $p3, $p;

    is_deeply $p->getCoordinates, [$c];

    is $p->getArea, 0;
    is $p->getLength, 0;

    my $c2 = Geo::Geos::Coordinate->new(2,2);
    is $gf->createPoint($c2)->distance($p), 1;

    is $p->getCentroid, $p;
};

done_testing;
