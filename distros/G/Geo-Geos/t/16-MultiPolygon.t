use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::PrecisionModel qw/TYPE_FLOATING_SINGLE/;
use Geo::Geos::Geometry qw/TYPE_GEOS_LINESTRING TYPE_GEOS_LINEARRING TYPE_GEOS_POLYGON TYPE_GEOS_MULTIPOLYGON TYPE_CAP_FLAT/;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Dimension qw/TYPE_DONTCARE TYPE_True TYPE_False TYPE_P TYPE_L TYPE_A/;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "empty" => sub {
    my $obj = $gf->createMultiPolygon;
    ok $obj;
    ok $obj->isSimple();
    is $obj->getNumPoints, 0;
    is $obj->getDimension, TYPE_A;
    is $obj->getCoordinateDimension, 2;
    is $obj->getBoundaryDimension, 1;
    is $obj->getCoordinate, undef;
    is $obj->getGeometryType, "MultiPolygon";
    is $obj->getGeometryTypeId, TYPE_GEOS_MULTIPOLYGON;
    ok $obj->isa('Geo::Geos::Polygonal');
    ok $obj->isa('Geo::Geos::GeometryCollection');
};

subtest "from coordinate sequence" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(5,0);
    my $c4 = Geo::Geos::Coordinate->new(1,0);

    my $lr1 = $gf->createLinearRing([$c1, $c2, $c3, $c4, $c1], 2);
    my $p1 = $gf->createPolygon($lr1);

    my $cx1 = Geo::Geos::Coordinate->new(15, 15);
    my $cx2 = Geo::Geos::Coordinate->new(4, 15);
    my $cx3 = Geo::Geos::Coordinate->new(4, 5);
    my $cx4 = Geo::Geos::Coordinate->new(15, 5);
    my $lr2 = $gf->createLinearRing([$cx1, $cx2, $cx3, $cx4, $cx1], 2);
    my $p2 = $gf->createPolygon($lr2);

    my $o = $gf->createMultiPolygon([$p1, $p2]);
    ok $o;


    subtest "geometry methods" => sub {
        is $o->getNumPoints, 10;

        $o->setSRID(5);
        is $o->getSRID, 5;

        is $o->getArea, 118;
        is $o->getLength, 54;
        is $o->clone, $o;
        is $o->distance($gf->createPoint($c2)), 0;
        ok $o->isWithinDistance($gf->createPoint($c2), 0.1);

        is $o->getGeometryType, "MultiPolygon";
        is $o->getGeometryTypeId, TYPE_GEOS_MULTIPOLYGON;

        like $o->getBoundary, qr/MULTILINESTRING.+/;
        is $o->getBoundaryDimension, 1;
        is $o->getCoordinateDimension, 2;
        ok $o->equalsExact($o);
        ok $o->equalsExact($o, 1.2);
        is $o->compareTo($o), 0;

        is $o->getNumGeometries, 2;
        is $o->getGeometryN(0)->getCoordinate, $c1;
        is_deeply $o->getCoordinates, [$c1, $c2, $c3, $c4, $c1, $cx1, $cx2, $cx3, $cx4, $cx1];
        is $o->getCoordinate, $c1;

        ok $o->getPrecisionModel->isFloating;

        like $o->getCentroid, qr/POINT.*/;
        is $o->getInteriorPoint, $gf->createPoint(Geo::Geos::Coordinate->new(9.5, 10.0));

        is $o->symDifference($o), 'GEOMETRYCOLLECTION EMPTY';
        is $o->difference($o), 'GEOMETRYCOLLECTION EMPTY';
        like $o->Union($o), qr/MULTIPOLYGON.*/;
        like $o->intersection($o), qr/MULTIPOLYGON.*/;
        like $o->convexHull, qr/POLYGON.*/;

        is $o->buffer(1)->getGeometryTypeId, TYPE_GEOS_MULTIPOLYGON;
        is $o->buffer(1, 2)->getGeometryTypeId, TYPE_GEOS_MULTIPOLYGON;
        is $o->buffer(1, 3, TYPE_CAP_FLAT)->getGeometryTypeId, TYPE_GEOS_MULTIPOLYGON;
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

        is( $o->relate($o)->toString, "2FFF1FFF2");
        ok !$o->relate($o, 'T*T******');

        $o->normalize;
    };
};

done_testing;
