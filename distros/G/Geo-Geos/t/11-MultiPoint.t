use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::PrecisionModel qw/TYPE_FLOATING_SINGLE/;
use Geo::Geos::Geometry qw/TYPE_GEOS_MULTIPOINT TYPE_GEOS_POLYGON TYPE_GEOS_MULTIPOLYGON TYPE_CAP_FLAT/;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Dimension qw/TYPE_DONTCARE TYPE_True TYPE_False TYPE_P TYPE_L TYPE_A/;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "empty multi-point" => sub {
    my $mp = $gf->createMultiPoint;
    ok $mp;
    ok $mp->isEmpty();
    ok $mp->isSimple();
    is $mp->getNumPoints, 0;
    is $mp->getDimension, TYPE_P;
    is $mp->getCoordinateDimension, 2;
    is $mp->getBoundaryDimension, -1;
    is $mp->getCoordinate, undef;
    is $mp->getGeometryType, "MultiPoint";
    is $mp->getGeometryTypeId, TYPE_GEOS_MULTIPOINT;
    ok $mp->isa('Geo::Geos::Puntal');
    ok $mp->isa('Geo::Geos::GeometryCollection');
};

subtest "multi-point from coordinate sequence" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);

    my $p = $gf->createMultiPoint([$c1, $c2], 2);
    ok !$p->isEmpty();

    subtest "geometry methods" => sub {
        is $p->getNumPoints, 2;

        $p->setSRID(5);
        is $p->getSRID, 5;
        is $p->getArea, 0;
        is $p->getLength, 0;
        is $p->clone, $p;
        is $p->distance($gf->createPoint($c2)), 0;
        ok $p->isWithinDistance($gf->createPoint($c2), 0.1);

        is $p->getGeometryType, "MultiPoint";
        is $p->getGeometryTypeId, TYPE_GEOS_MULTIPOINT;

        is $p->getBoundary->toString, "GEOMETRYCOLLECTION EMPTY";
        is $p->getBoundaryDimension, -1;
        is $p->getCoordinateDimension, 2;
        ok $p->equalsExact($p);
        ok $p->equalsExact($p, 1.2);
        is $p->compareTo($p), 0;

        is $p->getNumGeometries, 2;
        is $p->getGeometryN(0)->getCoordinate, $c1;
        is $p->getGeometryN(1)->getCoordinate, $c2;
        is_deeply $p->getCoordinates, [$c1, $c2];
        is $p->getCoordinate, $c1;

        ok $p->getPrecisionModel->isFloating;

        is $p->getCentroid, $gf->createPoint(Geo::Geos::Coordinate->new(3,2));
        is $p->getInteriorPoint, $gf->createPoint($c1);

        is $p->symDifference($p), 'GEOMETRYCOLLECTION EMPTY';
        is $p->difference($p), 'GEOMETRYCOLLECTION EMPTY';
        is $p->Union($p), $p;
        is $p->intersection($p), $p;
        is $p->convexHull, 'LINESTRING (1.0000000000000000 2.0000000000000000, 5.0000000000000000 2.0000000000000000)';

        is $p->buffer(1)->getGeometryTypeId, TYPE_GEOS_MULTIPOLYGON;
        is $p->buffer(1, 2)->getGeometryTypeId, TYPE_GEOS_MULTIPOLYGON;
        is $p->buffer(1, 3, TYPE_CAP_FLAT)->getGeometryTypeId, TYPE_GEOS_POLYGON;
        is $p->toText, $p->toString;

        ok $p->covers($p);
        ok $p->coveredBy($p);
        ok $p->equals($p);
        ok !$p->overlaps($p);
        ok $p->contains($p);
        ok $p->within($p);
        ok !$p->crosses($p);
        ok $p->intersects($p);
        ok !$p->touches($p);
        ok !$p->disjoint($p);
        like $p->getEnvelope, qr/POLYGON.+/;

        ok !$p->isRectangle;
        ok $p->isValid;
        ok !$p->isEmpty;
        ok $p->isSimple();

        is( $p->relate($p)->toString, "0FFFFFFF2");
        ok !$p->relate($p, 'T*T******');

        $p->normalize;
    };
};

done_testing;
