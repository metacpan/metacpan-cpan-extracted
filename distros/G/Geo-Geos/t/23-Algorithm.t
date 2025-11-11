use 5.012;
use warnings;
use Test::More;
use Test::Warnings;
use Test::Fatal;

use Geo::Geos::Coordinate;
use Geo::Geos::GeometryFactory;
use Geo::Geos::PrecisionModel;

use Geo::Geos::Algorithm;
use Geo::Geos::Algorithm qw/isPointInRing locatePointInRing isOnLine isCCW computeOrientation
                       orientationIndex distancePointLine distancePointLinePerpendicular
                       distanceLineLine signedArea getIntersection convexHull
                       interiorPointArea interiorPointLine interiorPointPoint
                       locate intersects signOfDet2x2
                       locateIndexedPointInArea locateSimplePointInArea/;
use Geo::Geos::Algorithm::HCoordinate;
use Geo::Geos::Algorithm::MinimumDiameter;
use Geo::Geos::Algorithm::LineIntersector;


subtest "CGA" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(5,0);
    my $c4 = Geo::Geos::Coordinate->new(1,0);

    my $coords_ring = [$c1, $c2, $c3, $c4, $c1];

    ok isPointInRing($c1, $coords_ring);
    is locatePointInRing($c1, $coords_ring), 1;
    ok !isOnLine($c3, [$c1, $c2]);
    ok !isCCW($coords_ring);
    is computeOrientation($c1, $c2, $c3), TYPE_TURN_CLOCKWISE;
    is orientationIndex($c1, $c2, $c3), TYPE_TURN_CLOCKWISE;

    is distancePointLine($c3, $c1, $c2), 2;
    is distancePointLinePerpendicular($c3, $c1, $c2), 2;
    is distanceLineLine($c1, $c2, $c3, $c4), 2;

    is signedArea($coords_ring), 8;
    is Geo::Geos::Algorithm::length($coords_ring), 12;
};

subtest "CentralEndpointIntersector" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(3,10);
    my $c4 = Geo::Geos::Coordinate->new(3,0);
    my $c = getIntersection($c1, $c2, $c3, $c4);
    ok !$c->isNull();
    is $c, $c1; # ???
};

subtest "ConvexHull" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(5,0);
    my $c4 = Geo::Geos::Coordinate->new(1,0);
    my $gf = Geo::Geos::GeometryFactory::create();

    my $lr = $gf->createLinearRing([$c1, $c2, $c3, $c4, $c1], 2);

    my $ch = convexHull($lr);
    ok $ch;
    is $ch->toString, 'POLYGON ((1.0000000000000000 0.0000000000000000, 1.0000000000000000 2.0000000000000000, 5.0000000000000000 2.0000000000000000, 5.0000000000000000 0.0000000000000000, 1.0000000000000000 0.0000000000000000))';

    like exception { convexHull(undef) }, qr/undef not allowed/;
};

subtest "InteriorPoint*" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(5,0);
    my $c4 = Geo::Geos::Coordinate->new(1,0);
    my $gf = Geo::Geos::GeometryFactory::create();

    my $lr = $gf->createLinearRing([$c1, $c2, $c3, $c4, $c1], 2);
    my $p = $gf->createPolygon($lr);

    my $ip1 = interiorPointArea($p);
    ok $ip1;
    is $ip1, Geo::Geos::Coordinate->new(3,1);
    like exception { interiorPointArea(undef) }, qr/undef not allowed/;

    my $l = $gf->createLineString([$c1, $c2], 2);
    my $ip2 = interiorPointLine($l);
    ok $ip2;
    is $ip2, $c1; # ? why not 3.2?
    like exception { interiorPointLine(undef) }, qr/undef not allowed/;

    my $ip3 = interiorPointPoint($gf->createPoint($c2));
    ok $ip3;
    is $ip3, $c2;
    like exception { interiorPointPoint(undef) }, qr/undef not allowed/;
};

subtest "PointLocator" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(5,0);
    my $c4 = Geo::Geos::Coordinate->new(1,0);
    my $gf = Geo::Geos::GeometryFactory::create();

    my $lr = $gf->createLinearRing([$c1, $c2, $c3, $c4, $c1], 2);
    is locate($c1, $lr), 0; # no idea what is 0
    ok intersects($c1, $lr);

    like exception { locate($c1, undef) }, qr/undef not allowed/;
    like exception { intersects($c1, undef) }, qr/undef not allowed/;

};

subtest "RobustDeterminant" => sub {
    is signOfDet2x2(1,2,3,4), -1;
};

subtest "HCoordinate" => sub {
    my $hc1 = Geo::Geos::Algorithm::HCoordinate->new(1,2,3);
    ok $hc1;
    is $hc1->x, 1;
    is $hc1->y, 2;
    is $hc1->w, 3;

    my $c = $hc1->getCoordinate;
    ok $c;

    my $hc2 = Geo::Geos::Algorithm::HCoordinate->new(
        Geo::Geos::Coordinate->new(1,2),
        Geo::Geos::Coordinate->new(-5,3)
    );
    ok $hc2;
    is $hc2->x, 0;
    is $hc2->y, 0;
    is $hc2->w, 0;

    my $hc3 = Geo::Geos::Algorithm::HCoordinate->new($c);
    ok $hc3;
    is $hc3->x, $c->x;
    is $hc3->y, $c->y;

    my $hc4 = Geo::Geos::Algorithm::HCoordinate->new($hc1, $hc2);
    ok $hc4;

    my $hc5 = Geo::Geos::Algorithm::HCoordinate->new(
        Geo::Geos::Coordinate->new(1,2),
        Geo::Geos::Coordinate->new(5,3),
        Geo::Geos::Coordinate->new(0,0),
        Geo::Geos::Coordinate->new(0,7),
    );
    ok $hc5;
    is $hc5->toString, '(0, 49) [w: 28]';

    my $ci = Geo::Geos::Algorithm::HCoordinate::intersection(
        Geo::Geos::Coordinate->new(1,2),
        Geo::Geos::Coordinate->new(5,3),
        Geo::Geos::Coordinate->new(0,0),
        Geo::Geos::Coordinate->new(0,7),
    );
    ok $ci;
};

subtest "LineIntersector" => sub {
    my $c1 = Geo::Geos::Coordinate->new(0,1);
    my $c2 = Geo::Geos::Coordinate->new(2,1);
    my $c3 = Geo::Geos::Coordinate->new(1,0);
    my $c4 = Geo::Geos::Coordinate->new(1,2);

    my $pm1 = Geo::Geos::PrecisionModel->new;
    my $li1 = Geo::Geos::Algorithm::LineIntersector->new($pm1);
    ok $li1;
    $li1->computeIntersection($c1, $c2, $c3);
    ok !$li1->hasIntersection;

    my $li2 = Geo::Geos::Algorithm::LineIntersector->new;
    ok $li2;
    $li2->setPrecisionModel($pm1);

    $li2->computeIntersection($c1, $c2, $c3, $c4);
    ok $li2->hasIntersection;
    is $li2->toString, "0 1_2 1 1 0_1 2 :  proper";
    is $li2->getIntersectionNum, 1;
    ok $li2->isProper;
    is $li2->getIndexAlongSegment(0, 0), 1;
    is $li2->getEdgeDistance(0, 0), 1;

    my $c = $li2->getIntersectionAlongSegment(1, 0);
    is $c, Geo::Geos::Coordinate->new(0,0); # ?

    subtest "static methods" => sub {
        my $c1 = Geo::Geos::Coordinate->new(0,1,1);
        my $c2 = Geo::Geos::Coordinate->new(2,1,2);
        my $c3 = Geo::Geos::Coordinate->new(1,0,3);
        my $z = Geo::Geos::Algorithm::LineIntersector::interpolateZ($c1, $c2, $c3);
        ok( abs($z - 3.41421356237309) < 0.00000001);

        my $d = Geo::Geos::Algorithm::LineIntersector::computeEdgeDistance($c1, $c2, $c3);
        is $d, 2;
        ok Geo::Geos::Algorithm::LineIntersector::isSameSignAndNonZero(-1, -2);
        ok !Geo::Geos::Algorithm::LineIntersector::hasIntersection($c1, $c2, $c3);
    };

    subtest "safety check" => sub {
        subtest "via c-tor" => sub {
            my $li;
            {
                my $pm2 = Geo::Geos::PrecisionModel->new;
                $li = Geo::Geos::Algorithm::LineIntersector->new($pm2);
                $li->computeIntersection($c1, $c2, $c3, $c4);
            };
            is $li->getEdgeDistance(0, 0), 1;
        };

        subtest "via setter" => sub {
            my $li = Geo::Geos::Algorithm::LineIntersector->new;
            {
                $li->setPrecisionModel(Geo::Geos::PrecisionModel->new);
            };
            $li->computeIntersection($c1, $c2, $c3, $c4);
            is $li->getEdgeDistance(0, 0), 1;

            $li->setPrecisionModel(Geo::Geos::PrecisionModel->new);
            is $li->getEdgeDistance(0, 0), 1;
        };
    };

};

subtest "locate" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(5,0);
    my $c4 = Geo::Geos::Coordinate->new(1,0);
    my $gf = Geo::Geos::GeometryFactory::create();

    my $lr = $gf->createLinearRing([$c1, $c2, $c3, $c4, $c1], 2);
    my $p = $gf->createPolygon($lr);

    is locateIndexedPointInArea($c2, $p), 1;
    is locateSimplePointInArea($c2, $p), 0;

    like exception { locateIndexedPointInArea(undef, $p) }, qr/undef not allowed/;
    like exception { locateSimplePointInArea(undef, $p) }, qr/undef not allowed/;
    like exception { locateSimplePointInArea($c1, undef) }, qr/undef not allowed/;

};

done_testing;
