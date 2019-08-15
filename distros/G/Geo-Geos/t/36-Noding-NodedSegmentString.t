use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Algorithm::LineIntersector;
use Geo::Geos::Coordinate;
use Geo::Geos::Noding::NodedSegmentString;
use Geo::Geos::PrecisionModel;

subtest "NodedSegmentString" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(7,1);
    my $c4 = Geo::Geos::Coordinate->new(9,1.5);
    my $c5 = Geo::Geos::Coordinate->new(10,2);
    my $pm = Geo::Geos::PrecisionModel->new;

    my $ss = Geo::Geos::Noding::NodedSegmentString->new([$c1, $c2, $c3]);
    ok $ss;
    ok !$ss->isClosed;
    is $ss->size, 3;
    is $ss->getCoordinate(0), $c1;
    my $coords = $ss->getCoordinates;
    is_deeply $coords, [$c1, $c2, $c3];
    like $ss->toString, qr/\QLINESTRING(1 2, 5 2, 7 1)\E/;
    like "$ss", qr/\QLINESTRING(1 2, 5 2, 7 1)\E/;

    subtest "SegmentNode" => sub {
        my $node1 = $ss->addIntersectionNode($c4, 2);
        ok $node1;
        ok $node1->isInterior;
        ok $node1->isEndPoint(2);
        is $node1->segmentIndex, 2;
        is $node1->coord, $c4;
        like $node1->toString, qr/\Q9 1.5 seg#=2 octant#=-1\E/;
        my $node2 = $ss->addIntersectionNode($c5, 0);
        is $node2->compareTo($node1), -1;
    };

    subtest "addIntersection / addIntersections" => sub {
        my $ss = Geo::Geos::Noding::NodedSegmentString->new([$c1, $c2, $c3]);
        my $c6 = Geo::Geos::Coordinate->new(11,2);
        $ss->addIntersection($c6, 1);
        $ss->getCoordinates;
        like $ss->toString, qr/Nodes: 1/;

        my $li1 = Geo::Geos::Algorithm::LineIntersector->new($pm);
        $ss->addIntersection($li1, 1, 1, 1);
        like $ss->toString, qr/Nodes: 2/;

        my $c_1 = Geo::Geos::Coordinate->new(10,1);
        my $c_2 = Geo::Geos::Coordinate->new(12,1);
        my $c_3 = Geo::Geos::Coordinate->new(11,0);
        my $c_4 = Geo::Geos::Coordinate->new(11,2);

        my $li2 = Geo::Geos::Algorithm::LineIntersector->new($pm);
        $li2->computeIntersection($c_1, $c_2, $c_3, $c_4);
        $ss->addIntersections($li2, 1, 4);
        like $ss->toString, qr/Nodes: 3/;
    };
};

done_testing;
