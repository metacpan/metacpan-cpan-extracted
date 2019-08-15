use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::PrecisionModel qw/TYPE_FLOATING_SINGLE/;
use Geo::Geos::Geometry qw/TYPE_GEOS_LINESTRING TYPE_GEOS_LINEARRING TYPE_GEOS_POLYGON TYPE_CAP_FLAT/;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Dimension qw/TYPE_DONTCARE TYPE_True TYPE_False TYPE_P TYPE_L TYPE_A/;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "empty line string" => sub {
    my $obj = $gf->createPolygon;
    ok $obj;
    ok $obj->isSimple();
    is $obj->getNumPoints, 0;
    is $obj->getDimension, TYPE_A;
    is $obj->getCoordinateDimension, 3;
    is $obj->getBoundaryDimension, 1;
    is $obj->getCoordinate, undef;
    is $obj->getGeometryType, "Polygon";
    is $obj->getGeometryTypeId, TYPE_GEOS_POLYGON;
    ok $obj->isa('Geo::Geos::Polygonal');
};

subtest "from coordinate sequence" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(5,0);
    my $c4 = Geo::Geos::Coordinate->new(1,0);

    my $lr = $gf->createLinearRing([$c1, $c2, $c3, $c4, $c1], 2);
    ok $lr;

    my $o = $gf->createPolygon($lr);
    ok $o;

    subtest "class-specific methods" => sub {
        is $o->getExteriorRing, $lr;
        is $o->getNumInteriorRing, 0;

        subtest "polygone with hole" => sub {
            my $cx1 = Geo::Geos::Coordinate->new(1.5,1.5);
            my $cx2 = Geo::Geos::Coordinate->new(4,1.5);
            my $cx3 = Geo::Geos::Coordinate->new(4,0.5);
            my $cx4 = Geo::Geos::Coordinate->new(1.5,0.5);
            my $lr_hole = $gf->createLinearRing([$cx1, $cx2, $cx3, $cx4, $cx1], 2);

            my $o2 = $gf->createPolygon($lr, [$lr_hole]);
            ok $o2;
            is $o2->getNumInteriorRing, 1;
            is $o2->getInteriorRingN(0), $lr_hole;
            is $o2->getArea, 5.5;
            #is $o2->getInteriorRingN(1), undef; - leads to crash in libgeos
        };

        ok $o->equals($o->reverse->reverse);
    };

    subtest "geometry methods" => sub {
        is $o->getNumPoints, 5;

        $o->setSRID(5);
        is $o->getSRID, 5;

        is $o->getArea, 8;
        is $o->getLength, 12;
        is $o->clone, $o;
        is $o->distance($gf->createPoint($c2)), 0;
        ok $o->isWithinDistance($gf->createPoint($c2), 0.1);

        is $o->getGeometryType, "Polygon";
        is $o->getGeometryTypeId, TYPE_GEOS_POLYGON;

        is $o->getBoundary, $gf->createLineString([$c1,  $c2, $c3, $c4, $c1], 2);
        is $o->getBoundaryDimension, 1;
        is $o->getCoordinateDimension, 2;
        ok $o->equalsExact($o);
        ok $o->equalsExact($o, 1.2);
        is $o->compareTo($o), 0;

        is $o->getNumGeometries, 1;
        is $o->getGeometryN(0)->getCoordinate, $c1;
        is_deeply $o->getCoordinates, [$c1, $c2, $c3, $c4, $c1];
        is $o->getCoordinate, $c1;

        ok $o->getPrecisionModel->isFloating;

        is $o->getCentroid, $gf->createPoint(Geo::Geos::Coordinate->new(3,1));
        is $o->getInteriorPoint, $gf->createPoint(Geo::Geos::Coordinate->new(3,1));

        is $o->symDifference($o), 'GEOMETRYCOLLECTION EMPTY';
        is $o->difference($o), 'GEOMETRYCOLLECTION EMPTY';
        is $o->Union($o), $o;
        is $o->intersection($o), $o;
        like $o->convexHull, qr/POLYGON.*/;

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

        ok $o->isRectangle;
        ok $o->isValid;
        ok !$o->isEmpty;
        ok $o->isSimple();

        is( $o->relate($o)->toString, "2FFF1FFF2");
        ok !$o->relate($o, 'T*T******');

        $o->normalize;
    };
};

subtest "tesselation" => sub {
=x
    subtest "square poly tesselation (no holes)" => sub {
        my $lr = $gf->createLinearRing([
            Geo::Geos::Coordinate->new(0,0),
            Geo::Geos::Coordinate->new(100,0),
            Geo::Geos::Coordinate->new(100,100),
            Geo::Geos::Coordinate->new(0,100),
            Geo::Geos::Coordinate->new(0,0),
        ], 2);
        my $p = $gf->createPolygon($lr);
        my $coll = $p->tesselate;
        ok $coll;
        is $coll->getNumGeometries, 2;
        my $t1 = $coll->getGeometryN(0);
        my $t2 = $coll->getGeometryN(1);
        is $t1->toString, 'POLYGON ((100.0000000000000000 100.0000000000000000, 0.0000000000000000 100.0000000000000000, 0.0000000000000000 0.0000000000000000, 100.0000000000000000 100.0000000000000000))';
        is $t2->toString, 'POLYGON ((0.0000000000000000 0.0000000000000000, 100.0000000000000000 0.0000000000000000, 100.0000000000000000 100.0000000000000000, 0.0000000000000000 0.0000000000000000))';
    };
=cut

    subtest "square poly with hole tesselation" => sub {
        my $lr = $gf->createLinearRing([
            Geo::Geos::Coordinate->new(0,0),
            Geo::Geos::Coordinate->new(100,0),
            Geo::Geos::Coordinate->new(100,100),
            Geo::Geos::Coordinate->new(0,100),
            Geo::Geos::Coordinate->new(0,0),
        ], 2);
        my $hole = $gf->createLinearRing([
            Geo::Geos::Coordinate->new(75,25),
            Geo::Geos::Coordinate->new(75,75),
            Geo::Geos::Coordinate->new(25,75),
            Geo::Geos::Coordinate->new(2,25),
            Geo::Geos::Coordinate->new(75,25),
        ], 2);
        my $p = $gf->createPolygon($lr, [$hole]);
        my $coll = $p->tesselate;
        ok $coll;
        is $coll->getNumGeometries, 8;
        is $coll->getGeometryN(0)->toString, 'POLYGON ((0.0000000000000000 100.0000000000000000, 0.0000000000000000 0.0000000000000000, 2.0000000000000000 25.0000000000000000, 0.0000000000000000 100.0000000000000000))';
=x
        my $t1 = $coll->getGeometryN(0);
        my $t2 = $coll->getGeometryN(1);
        is $t1->toString, 'zzz';
        is $t2->toString, 'zzz';
=cut
    };
};

done_testing;
