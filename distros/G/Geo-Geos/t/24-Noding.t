use 5.012;
use warnings;
use Test::Fatal;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::GeometryFactory;
use Geo::Geos::PrecisionModel;
use Geo::Geos::Prep::GeometryFactory;

use Geo::Geos::Noding qw/compareOrientedCoordinateArray octant checkNodingValid fastCheckNodingValid
                    compareSegmentPoints extractSegmentStrings intersects/;

use Geo::Geos::Algorithm::LineIntersector;
use Geo::Geos::Noding::NodedSegmentString;
use Geo::Geos::Noding::BasicSegmentString;

subtest "noding" => sub {
    subtest "OrientedCoordinateArray" => sub {
        my $c1 = Geo::Geos::Coordinate->new(0,1);
        my $c2 = Geo::Geos::Coordinate->new(2,1);
        is compareOrientedCoordinateArray([$c1], [$c2]), -1;
    };

    subtest "OrientedCoordinateArray, octant" => sub {
        my $c1 = Geo::Geos::Coordinate->new(0,1);
        my $c2 = Geo::Geos::Coordinate->new(2,1);
        is octant($c1, $c2), 0;
        is octant(1, 3), 1;
    };

    subtest "NodingValidator / FastNodingValidator" => sub {
        my $c1 = Geo::Geos::Coordinate->new(0,1);
        my $c2 = Geo::Geos::Coordinate->new(2,1);
        my $c3 = Geo::Geos::Coordinate->new(1,0);
        my $c4 = Geo::Geos::Coordinate->new(1,2);

        my $ss1 = Geo::Geos::Noding::NodedSegmentString->new([$c1, $c2]);
        my $ss2 = Geo::Geos::Noding::NodedSegmentString->new([$c3, $c4]);

        like exception { checkNodingValid([$ss1, $ss2]) }, qr/TopologyException/;
        like exception { fastCheckNodingValid([$ss1, $ss2]) }, qr/TopologyException/;

        is fastCheckNodingValid([$ss1]), undef;
        my $err = fastCheckNodingValid([$ss1, $ss2]);
        is $err, 'found non-noded intersection between LINESTRING (0 1, 2 1) and LINESTRING (1 0, 1 2)';
    };

    subtest "SegmentPointComparator" => sub {
        my $c1 = Geo::Geos::Coordinate->new(0,1);
        my $c2 = Geo::Geos::Coordinate->new(2,1);
        is( compareSegmentPoints(4, $c1, $c2), 1);
    };

    subtest "SegmentStringUtil" => sub {
        my $gf = Geo::Geos::GeometryFactory::create();
        my $c1 = Geo::Geos::Coordinate->new(1,2);
        my $c2 = Geo::Geos::Coordinate->new(5,2);
        my $ls = $gf->createLineString([$c1, $c2], 2);

        my $ss = extractSegmentStrings($ls);
        ok $ss;
        is scalar(@$ss), 1;
        like $ss->[0]->toString, qr/\QLINESTRING(1 2, 5 2)\E/;
    };

    subtest "FastSegmentSetIntersectionFinder" => sub {
        my $c1 = Geo::Geos::Coordinate->new(0,1);
        my $c2 = Geo::Geos::Coordinate->new(2,1);
        my $c3 = Geo::Geos::Coordinate->new(1,0);
        my $c4 = Geo::Geos::Coordinate->new(1,2);

        my $ss1 = Geo::Geos::Noding::NodedSegmentString->new([$c1, $c2]);
        my $ss2 = Geo::Geos::Noding::NodedSegmentString->new([$c3, $c4]);
        ok intersects([$ss1], [$ss2]);

        my $pm = Geo::Geos::PrecisionModel->new;
        my $li = Geo::Geos::Algorithm::LineIntersector->new($pm);
        my $sid = Geo::Geos::Noding::SegmentIntersectionDetector->new($li);
        ok intersects([$ss1], [$ss2], $sid);
    };
};

done_testing;
