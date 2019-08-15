use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::PrecisionModel qw/TYPE_FLOATING_SINGLE/;
use Geo::Geos::Geometry qw/TYPE_GEOS_LINESTRING TYPE_GEOS_POLYGON TYPE_GEOS_POLYGON TYPE_CAP_FLAT/;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Dimension qw/TYPE_DONTCARE TYPE_True TYPE_False TYPE_P TYPE_L TYPE_A/;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "empty line string" => sub {
    my $obj = $gf->createLineString;
    ok $obj;
    ok $obj->isEmpty();
    ok $obj->isSimple();
    is $obj->getNumPoints, 0;
    is $obj->getDimension, TYPE_L;
    is $obj->getCoordinateDimension, 3;
    is $obj->getBoundaryDimension, 0;
    is $obj->getCoordinate, undef;
    is $obj->getGeometryType, "LineString";
    is $obj->getGeometryTypeId, TYPE_GEOS_LINESTRING;
    ok $obj->isa('Geo::Geos::Lineal');
};

subtest "from coordinate sequence" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);

    my $o = $gf->createLineString([$c1, $c2], 2);
    ok !$o->isEmpty();

    subtest "class-specific methods" => sub {
        ok !$o->isRing;
        ok !$o->isClosed;
        is $o->getStartPoint, $gf->createPoint($c1);
        is $o->getPointN(0), $gf->createPoint($c1);
        is $o->getEndPoint, $gf->createPoint($c2);
        is $o->reverse, $gf->createLineString([$c2, $c1], 2);
    };

    subtest "geometry methods" => sub {
        is $o->getNumPoints, 2;

        $o->setSRID(5);
        is $o->getSRID, 5;

        is $o->getArea, 0;
        is $o->getLength, 4;
        is $o->clone, $o;
        is $o->distance($gf->createPoint($c2)), 0;
        ok $o->isWithinDistance($gf->createPoint($c2), 0.1);

        is $o->getGeometryType, "LineString";
        is $o->getGeometryTypeId, TYPE_GEOS_LINESTRING;

        is $o->getBoundary, $gf->createMultiPoint([$c1, $c2], 2);
        is $o->getBoundaryDimension, 0;
        is $o->getCoordinateDimension, 2;
        ok $o->equalsExact($o);
        ok $o->equalsExact($o, 1.2);
        is $o->compareTo($o), 0;

        is $o->getNumGeometries, 1;
        is $o->getGeometryN(0)->getCoordinate, $c1;
        is_deeply $o->getCoordinates, [$c1, $c2];
        is $o->getCoordinate, $c1;

        ok $o->getPrecisionModel->isFloating;

        is $o->getCentroid, $gf->createPoint(Geo::Geos::Coordinate->new(3,2));
        is $o->getInteriorPoint, $gf->createPoint($c1);

        is $o->symDifference($o), 'GEOMETRYCOLLECTION EMPTY';
        is $o->difference($o), 'GEOMETRYCOLLECTION EMPTY';
        is $o->Union($o), $o;
        is $o->intersection($o), $o;
        is $o->convexHull, 'LINESTRING (1.0000000000000000 2.0000000000000000, 5.0000000000000000 2.0000000000000000)';

        is $o->buffer(1)->getGeometryTypeId, TYPE_GEOS_POLYGON;
        is $o->buffer(1, 2)->getGeometryTypeId, TYPE_GEOS_POLYGON;
        is $o->buffer(1, 3, TYPE_CAP_FLAT)->getGeometryTypeId, TYPE_GEOS_POLYGON;
        is $o->toText, $o->toString;

        ok $o->covers($o);
        ok $o->coveredBy($o);
        ok $o->equals($o);
        ok !$o->overlaps($o);
        ok $o->contains($o);
        ok $o->within($o);
        ok !$o->crosses($o);
        ok $o->intersects($o);
        ok !$o->touches($o);
        ok !$o->disjoint($o);
        like $o->getEnvelope, qr/POLYGON.+/;

        ok !$o->isRectangle;
        ok $o->isValid;
        ok !$o->isEmpty;
        ok $o->isSimple();

        is( $o->relate($o)->toString, "1FFF0FFF2");
        ok !$o->relate($o, 'T*T******');

        $o->normalize;
    };
};

done_testing;
