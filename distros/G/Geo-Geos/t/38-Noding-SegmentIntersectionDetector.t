use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::PrecisionModel;
use Geo::Geos::Noding::BasicSegmentString;
use Geo::Geos::Noding::SegmentIntersectionDetector;

subtest "SegmentIntersectionDetector" => sub {
    my $c1 = Geo::Geos::Coordinate->new(0,1);
    my $c2 = Geo::Geos::Coordinate->new(2,1);
    my $c3 = Geo::Geos::Coordinate->new(1,0);
    my $c4 = Geo::Geos::Coordinate->new(1,2);

    my $ss1 = Geo::Geos::Noding::BasicSegmentString->new([$c1, $c2]);
    my $ss2 = Geo::Geos::Noding::BasicSegmentString->new([$c3, $c4]);

    my $li = Geo::Geos::Algorithm::LineIntersector->new(Geo::Geos::PrecisionModel->new);

    my $sid = Geo::Geos::Noding::SegmentIntersectionDetector->new($li);
    ok $sid;
    ok !$sid->isDone;

    $sid->processIntersections($ss1, 0, $ss2, 0);
    ok $li->hasIntersection;
    ok $sid->isDone;

    my $c = $sid->getIntersection;
    ok $c;
    is $c, Geo::Geos::Coordinate->new(1,1);
    my $segments = $sid->getIntersectionSegments;
    ok $segments;
    is scalar(@$segments), 4;

    ok $sid->hasProperIntersection;
    ok !$sid->hasNonProperIntersection;
};

done_testing;
