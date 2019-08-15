use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::PrecisionModel qw/TYPE_FLOATING_SINGLE/;
use Geo::Geos::Geometry qw/TYPE_GEOS_MULTILINESTRING TYPE_GEOS_POLYGON TYPE_GEOS_POLYGON TYPE_CAP_FLAT/;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Dimension qw/TYPE_DONTCARE TYPE_True TYPE_False TYPE_P TYPE_L TYPE_A/;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "empty line string" => sub {
    my $obj = $gf->createMultiLineString;
    ok $obj;
    ok $obj->isEmpty();
    ok $obj->isSimple();
    is $obj->getNumPoints, 0;
    is $obj->getDimension, TYPE_L;
    is $obj->getCoordinateDimension, 2;
    is $obj->getBoundaryDimension, 0;
    is $obj->getCoordinate, undef;
    is $obj->getGeometryType, "MultiLineString";
    is $obj->getGeometryTypeId, TYPE_GEOS_MULTILINESTRING;
    ok $obj->isa('Geo::Geos::Lineal');
    ok $obj->isa('Geo::Geos::GeometryCollection');
};

subtest "from coordinate sequence" => sub {
    my $c11 = Geo::Geos::Coordinate->new(1,2);
    my $c12 = Geo::Geos::Coordinate->new(5,2);
    my $c21 = Geo::Geos::Coordinate->new(10,2);
    my $c22 = Geo::Geos::Coordinate->new(15,2);

    my $l1 = $gf->createLineString([$c11, $c21], 2);
    my $l2 = $gf->createLineString([$c21, $c22], 2);
    my $o = $gf->createMultiLineString([$l1, $l2]);
    ok $o;
    ok !$o->isEmpty();

    subtest "class-specific methods" => sub {
        ok !$o->isClosed;
        my $o2 = $gf->createMultiLineString([
            $gf->createLineString([$c22, $c21], 2),
            $gf->createLineString([$c21, $c11], 2),
        ]);
        is ($o->reverse, $o2);
    };

    subtest "geometry methods" => sub {
        is $o->getNumPoints, 4;

        $o->setSRID(5);
        is $o->getSRID, 5;

        is $o->getArea, 0;
        is $o->getLength, 14;
        is $o->clone, $o;
        is $o->distance($gf->createPoint($c22)), 0;
        ok $o->isWithinDistance($gf->createPoint($c22), 0.1);

        is $o->getGeometryType, "MultiLineString";
        is $o->getGeometryTypeId, TYPE_GEOS_MULTILINESTRING;

        is $o->getBoundary, $gf->createMultiPoint([$c11, $c22], 2);
        is $o->getBoundaryDimension, 0;
        is $o->getCoordinateDimension, 2;
        ok $o->equalsExact($o);
        ok $o->equalsExact($o, 1.2);
        is $o->compareTo($o), 0;

        is $o->getNumGeometries, 2;
        is $o->getGeometryN(0), $l1;
        is_deeply $o->getCoordinates, [$c11, $c21, $c21, $c22]; # ???
        is $o->getCoordinate, $c11;

        ok $o->getPrecisionModel->isFloating;

        is $o->getCentroid, $gf->createPoint(Geo::Geos::Coordinate->new(8,2));
        is $o->getInteriorPoint, $gf->createPoint($c21);

        is $o->symDifference($o), 'GEOMETRYCOLLECTION EMPTY';
        is $o->difference($o), 'GEOMETRYCOLLECTION EMPTY';
        is $o->Union($o), $o;
        is $o->intersection($o), $o;
        is $o->convexHull, 'LINESTRING (1.0000000000000000 2.0000000000000000, 15.0000000000000000 2.0000000000000000)';

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
