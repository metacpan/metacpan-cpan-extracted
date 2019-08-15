use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::Geometry;
use Geo::Geos::GeometryFactory;
use Geo::Geos::Precision qw/signExpBits numCommonMostSigMantissaBits zeroLowerBits getBit
                       commonIntersection commonUnion commonDifference commonSymDifference
                       commonBuffer enhancedIntersection enhancedUnion enhancedDifference
                       enhancedSymDifference enhancedBuffer removeCommonBits addCommonBits/;

use Geo::Geos::Precision::GeometryPrecisionReducer;
use Geo::Geos::Precision::SimpleGeometryPrecisionReducer;
use Geo::Geos::PrecisionModel qw/TYPE_FIXED TYPE_FLOATING TYPE_FLOATING_SINGLE/;

my $gf = Geo::Geos::GeometryFactory::create();

subtest "CommonBits" => sub {
    is signExpBits(1234512222226), 0;
    is numCommonMostSigMantissaBits(1234512222226, 78774), 12;
    is zeroLowerBits(1234512222226, 4), 1234512222224;
    is getBit(1234512222226, 4), 1;
};

subtest "BitsOp" => sub {
    my $c1_1 = Geo::Geos::Coordinate->new(0,0);
    my $c1_2 = Geo::Geos::Coordinate->new(0,2);
    my $c1_3 = Geo::Geos::Coordinate->new(2,2);
    my $c1_4 = Geo::Geos::Coordinate->new(2,0);
    my $lr1 = $gf->createLinearRing([$c1_1, $c1_2, $c1_3, $c1_4, $c1_1], 2);
    my $p1 = $gf->createPolygon($lr1);

    my $c2_1 = Geo::Geos::Coordinate->new(1,0);
    my $c2_2 = Geo::Geos::Coordinate->new(1,2);
    my $c2_3 = Geo::Geos::Coordinate->new(3,2);
    my $c2_4 = Geo::Geos::Coordinate->new(3,0);
    my $lr2 = $gf->createLinearRing([$c2_1, $c2_2, $c2_3, $c2_4, $c2_1], 2);
    my $p2 = $gf->createPolygon($lr2);

    subtest "CommonBitsOp" => sub {
        subtest "do not revert to original precision" => sub {
            my $r_intersection = commonIntersection($p1, $p2);
            is $r_intersection, 'POLYGON ((1.0000000000000000 2.0000000000000000, 2.0000000000000000 2.0000000000000000, 2.0000000000000000 0.0000000000000000, 1.0000000000000000 0.0000000000000000, 1.0000000000000000 2.0000000000000000))';

            my $r_union = commonUnion($p1, $p2);
            is $r_union, 'POLYGON ((0.0000000000000000 0.0000000000000000, 0.0000000000000000 2.0000000000000000, 1.0000000000000000 2.0000000000000000, 2.0000000000000000 2.0000000000000000, 3.0000000000000000 2.0000000000000000, 3.0000000000000000 0.0000000000000000, 2.0000000000000000 0.0000000000000000, 1.0000000000000000 0.0000000000000000, 0.0000000000000000 0.0000000000000000))';

            my $r_diff = commonDifference($p2, $p1);
            is $r_diff, 'POLYGON ((2.0000000000000000 2.0000000000000000, 3.0000000000000000 2.0000000000000000, 3.0000000000000000 0.0000000000000000, 2.0000000000000000 0.0000000000000000, 2.0000000000000000 2.0000000000000000))';

            my $r_sdiff = commonSymDifference($p2, $p1);
            like $r_sdiff, qr/MULTIPOLYGON/;

            my $r_buff = commonBuffer($p1, 0.5);
            like $r_buff, qr/POLYGON.+0.0000000000000000 -0.5000000/;
        };

        subtest "do revert to original precision" => sub {
            my $r_intersection = commonIntersection($p1, $p2, 1);
            is $r_intersection, 'POLYGON ((1.0000000000000000 2.0000000000000000, 2.0000000000000000 2.0000000000000000, 2.0000000000000000 0.0000000000000000, 1.0000000000000000 0.0000000000000000, 1.0000000000000000 2.0000000000000000))';

            my $r_union = commonUnion($p1, $p2, 1);
            is $r_union, 'POLYGON ((0.0000000000000000 0.0000000000000000, 0.0000000000000000 2.0000000000000000, 1.0000000000000000 2.0000000000000000, 2.0000000000000000 2.0000000000000000, 3.0000000000000000 2.0000000000000000, 3.0000000000000000 0.0000000000000000, 2.0000000000000000 0.0000000000000000, 1.0000000000000000 0.0000000000000000, 0.0000000000000000 0.0000000000000000))';

            my $r_diff = commonDifference($p2, $p1, 1);
            is $r_diff, 'POLYGON ((2.0000000000000000 2.0000000000000000, 3.0000000000000000 2.0000000000000000, 3.0000000000000000 0.0000000000000000, 2.0000000000000000 0.0000000000000000, 2.0000000000000000 2.0000000000000000))';

            my $r_sdiff = commonSymDifference($p2, $p1, 1);
            like $r_sdiff, qr/MULTIPOLYGON/;

            my $r_buff = commonBuffer($p1, 0.5, 1);
            like $r_buff, qr/POLYGON.+0.0000000000000000 -0.5000000/;
        };
    };

    subtest "EnhancedPrecisionOp" => sub {
        my $r_intersection = enhancedIntersection($p1, $p2);
        is $r_intersection, 'POLYGON ((1.0000000000000000 2.0000000000000000, 2.0000000000000000 2.0000000000000000, 2.0000000000000000 0.0000000000000000, 1.0000000000000000 0.0000000000000000, 1.0000000000000000 2.0000000000000000))';

        my $r_union = enhancedUnion($p1, $p2);
        is $r_union, 'POLYGON ((0.0000000000000000 0.0000000000000000, 0.0000000000000000 2.0000000000000000, 1.0000000000000000 2.0000000000000000, 2.0000000000000000 2.0000000000000000, 3.0000000000000000 2.0000000000000000, 3.0000000000000000 0.0000000000000000, 2.0000000000000000 0.0000000000000000, 1.0000000000000000 0.0000000000000000, 0.0000000000000000 0.0000000000000000))';

        my $r_diff = enhancedDifference($p2, $p1);
        is $r_diff, 'POLYGON ((2.0000000000000000 2.0000000000000000, 3.0000000000000000 2.0000000000000000, 3.0000000000000000 0.0000000000000000, 2.0000000000000000 0.0000000000000000, 2.0000000000000000 2.0000000000000000))';

        my $r_sdiff = enhancedSymDifference($p2, $p1);
        like $r_sdiff, qr/MULTIPOLYGON/;

        my $r_buff = enhancedBuffer($p1, 0.5);
        like $r_buff, qr/POLYGON.+0.0000000000000000 -0.5000000/;
    };

};

subtest "CommonBitsRemover" => sub {
    my $c1_1 = Geo::Geos::Coordinate->new(0,1);
    my $c1_2 = Geo::Geos::Coordinate->new(1,1);
    my $c2_1 = Geo::Geos::Coordinate->new(0,2);
    my $c2_2 = Geo::Geos::Coordinate->new(1,2);
    my $c3_1 = Geo::Geos::Coordinate->new(0,3);
    my $c3_2 = Geo::Geos::Coordinate->new(1,3);

    my $ls1 = $gf->createLineString([$c1_1, $c1_2], 2);
    my $ls2 = $gf->createLineString([$c2_1, $c2_2], 2);
    my $ls3 = $gf->createLineString([$c3_1, $c3_2], 2);
    my $ls4 = $gf->createLineString([$c3_1, $c3_2], 2);

    my $c1 = removeCommonBits($ls3, [$ls1, $ls2]);
    is $c1->toString, '0 0';

    my $c2 = addCommonBits($ls4, [$ls1, $ls2]);
    is $c2->toString, '0 0';
};

subtest "GeometryPrecisionReducer" => sub {
    my $pm = Geo::Geos::PrecisionModel->new(2);
    my $pr = Geo::Geos::Precision::GeometryPrecisionReducer->new($pm);

    my $c1_1 = Geo::Geos::Coordinate->new(0.123,1);
    my $c1_2 = Geo::Geos::Coordinate->new(1.348,1);
    my $ls1 = $gf->createLineString([$c1_1, $c1_2], 2);

    $pr->setRemoveCollapsedComponents(1);
    $pr->setPointwise(1);
    my $r = $pr->reduce($ls1);
    ok $r;
    like $r->toString, qr/LINESTRING \(0.123.+ 1.0000000000000000, 1.348.+ 1.0000000000000000\)/;
    isnt $ls1->toString, $r->toString;
    isnt $ls1, $r;
};

subtest "SimpleGeometryPrecisionReducer" => sub {
    my $pm = Geo::Geos::PrecisionModel->new(2);
    my $pr = Geo::Geos::Precision::SimpleGeometryPrecisionReducer->new($pm);

    my $c1_1 = Geo::Geos::Coordinate->new(0.123,1);
    my $c1_2 = Geo::Geos::Coordinate->new(1.348,1);
    my $ls1 = $gf->createLineString([$c1_1, $c1_2], 2);

    $pr->setRemoveCollapsedComponents(1);
    is $pr->getRemoveCollapsed, 1;
    my $pm2 = $pr->getPrecisionModel;
    is $pm2, $pm;

    my $r = $pr->reduce($ls1);
    ok $r;
    like $r->toString, qr/LINESTRING \(0.123.+ 1.0000000000000000, 1.348.+ 1.0000000000000000\)/;
    isnt $ls1->toString, $r->toString;
    isnt $ls1, $r;
};

done_testing;
