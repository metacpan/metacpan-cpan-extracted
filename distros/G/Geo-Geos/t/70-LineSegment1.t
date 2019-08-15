use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::LineSegment;
use Geo::Geos::GeometryFactory;

subtest "c-tors, p0, p1" => sub {
    my $o1 = Geo::Geos::LineSegment->new;
    ok $o1;

    my $c1 = Geo::Geos::Coordinate->new(1, 1);
    my $c2 = Geo::Geos::Coordinate->new(5, 1);

    my $o2 = Geo::Geos::LineSegment->new($c1, $c2);
    ok $o2;
    is $o2->p0, $c1;
    is $o2->p1, $c2;

    my $o3 = Geo::Geos::LineSegment->new(1, 1, 2, 2);
    ok $o3;
};

subtest "getLength, isHorizontal, isVertical" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1, 1);
    my $c2 = Geo::Geos::Coordinate->new(5, 1);
    my $o = Geo::Geos::LineSegment->new($c1, $c2);

    is $o->getLength, 4;
    ok $o->isHorizontal;
    ok !$o->isVertical;
};

subtest "setCoordinates, orientationIndex" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1, 1);
    my $c2 = Geo::Geos::Coordinate->new(5, 1);
    my $c3 = Geo::Geos::Coordinate->new(1, 0);
    my $c4 = Geo::Geos::Coordinate->new(5, 0);

    my $o1 = Geo::Geos::LineSegment->new($c1, $c2);
    $o1->setCoordinates($c3, $c4);
    is $o1->p0, $c3;
    is $o1->p1, $c4;

    my $o2 = Geo::Geos::LineSegment->new($c1, $c3);
    $o1->setCoordinates($o2);
    is $o1->p0, $c1;
    is $o1->p1, $c3;

    is $o1->orientationIndex($c2), 1;
    is $o1->orientationIndex($o2), 0;
};

done_testing;
