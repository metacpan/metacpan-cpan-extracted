use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::PrecisionModel;
use Geo::Geos::Noding::BasicSegmentString;
use Geo::Geos::Noding::SingleInteriorIntersectionFinder;

subtest "SingleInteriorIntersectionFinder" => sub {
    my $c1 = Geo::Geos::Coordinate->new(0,1);
    my $c2 = Geo::Geos::Coordinate->new(1,1);

    my $c2_2 = Geo::Geos::Coordinate->new(1,0);
    my $c2_1 = Geo::Geos::Coordinate->new(1,2);

    my $ss1 = Geo::Geos::Noding::BasicSegmentString->new([$c1, $c2]);
    my $ss2 = Geo::Geos::Noding::BasicSegmentString->new([$c2_1, $c2_2]);

    my $li = Geo::Geos::Algorithm::LineIntersector->new(Geo::Geos::PrecisionModel->new);

    my $sid = Geo::Geos::Noding::SingleInteriorIntersectionFinder->new($li);
    ok $sid;
    ok !$sid->isDone;

    $sid->processIntersections($ss1, 0, $ss2, 0);
    ok $li->hasIntersection;
    ok $li->isInteriorIntersection;
    ok $sid->isDone;

    my $c = $sid->getInteriorIntersection;
    ok $c;
    is $c, Geo::Geos::Coordinate->new(1, 1);
    my $segments = $sid->getIntersectionSegments;
    ok $segments;
    is scalar(@$segments), 4;
};

done_testing;
