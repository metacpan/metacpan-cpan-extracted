use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::LineSegment;
use Geo::Geos::GeometryFactory;

subtest "reverse, normalize, angle, midPoint, toString" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1, 1);
    my $c2 = Geo::Geos::Coordinate->new(5, 1);
    my $o = Geo::Geos::LineSegment->new($c1, $c2);

    $o->reverse;
    is $o->p0, $c2;
    is $o->p1, $c1;

    $o->normalize;
    is $o->toString, "LINESEGMENT(1 1,5 1)";
    is $o, $o;
    is "$o", "$o";

    is $o->angle, 0;
    is $o->midPoint, Geo::Geos::Coordinate->new(3, 1);
};

subtest "distance, distancePerpendicular, pointAlong, pointAlongOffset" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1, 1);
    my $c2 = Geo::Geos::Coordinate->new(5, 1);
    my $c3 = Geo::Geos::Coordinate->new(1, 0);
    my $c4 = Geo::Geos::Coordinate->new(5, 0);

    my $o1 = Geo::Geos::LineSegment->new($c1, $c2);
    my $o2 = Geo::Geos::LineSegment->new($c3, $c4);

    is $o1->distance($o2), 1;
    is $o1->distance($c3), 1;
    is $o1->distancePerpendicular($c3), 1;
    is $o1->pointAlong(2), Geo::Geos::Coordinate->new(9, 1);
    is $o1->pointAlongOffset(2, -1), Geo::Geos::Coordinate->new(9, 0);
};

subtest "projectionFactor, segmentFraction, project, compareTo, equalsTopo" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1, 1);
    my $c2 = Geo::Geos::Coordinate->new(5, 1);
    my $c3 = Geo::Geos::Coordinate->new(1, 0);
    my $c4 = Geo::Geos::Coordinate->new(5, 0);

    my $o1 = Geo::Geos::LineSegment->new($c1, $c2);
    my $o2 = Geo::Geos::LineSegment->new($c3, $c4);

    is $o1->projectionFactor($c4), 1;
    is $o1->segmentFraction($c4), 1;

    is $o1->compareTo($o2), 1;
    ok !$o1->equalsTopo($o2);

    subtest "project" => sub {
        my $cx1 = $o1->project($c3);
        is $cx1, $c1;
        my ($cx2) = $o1->project($c3);
        is $cx2, $c1;

        my $lx1 = $o1->project($o2);
        is $lx1, $o1;
        my ($lx2, $overlap) = $o1->project($o2);
        is $lx2, $o1;
        ok $overlap;
    };
};

subtest "closestPoint, closestPoints" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1, 1);
    my $c2 = Geo::Geos::Coordinate->new(5, 1);
    my $c3 = Geo::Geos::Coordinate->new(1, 0);
    my $c4 = Geo::Geos::Coordinate->new(5, 0);

    my $o1 = Geo::Geos::LineSegment->new($c1, $c2);
    my $o2 = Geo::Geos::LineSegment->new($c3, $c4);

    is $o1->closestPoint(Geo::Geos::Coordinate->new(0, 1)), $c1;
    my $closest_points = $o1->closestPoints($o2);
    ok $closest_points;
    is scalar(@$closest_points), 2;
    is_deeply $closest_points, [$c1, $c3];
};

subtest "intersection, lineIntersection" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1, 1);
    my $c2 = Geo::Geos::Coordinate->new(5, 1);
    my $c3 = Geo::Geos::Coordinate->new(1, 0);
    my $c4 = Geo::Geos::Coordinate->new(5, 0);
    my $c5 = Geo::Geos::Coordinate->new(3, 0);
    my $c6 = Geo::Geos::Coordinate->new(3, 3);

    my $o1 = Geo::Geos::LineSegment->new($c1, $c2);
    my $o2 = Geo::Geos::LineSegment->new($c3, $c4);
    my $o3 = Geo::Geos::LineSegment->new($c5, $c6);

    my $i1 = $o1->intersection($o2);
    is $i1, undef;
    my $i2 = $o1->intersection($o3);
    is $i2, Geo::Geos::Coordinate->new(3, 1);

    my $i3 = $o1->lineIntersection($o2);
    is $i3, undef;
    my $i4 = $o1->lineIntersection($o3);
    is $i4, Geo::Geos::Coordinate->new(3, 1);
};

subtest "toGeometry" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1, 1);
    my $c2 = Geo::Geos::Coordinate->new(5, 1);
    my $gf = Geo::Geos::GeometryFactory::create;

    my $o = Geo::Geos::LineSegment->new($c1, $c2);
    my $ls = $o->toGeometry($gf);
    is $ls->toString, "LINESTRING (1.0000000000000000 1.0000000000000000, 5.0000000000000000 1.0000000000000000)";
};

done_testing;
