use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::PrecisionModel;
use Geo::Geos::Noding::NodedSegmentString;
use Geo::Geos::Noding::IntersectionAdder;

subtest "IntersectionAdder" => sub {
    my $c1 = Geo::Geos::Coordinate->new(0,1);
    my $c2 = Geo::Geos::Coordinate->new(2,1);
    my $c3 = Geo::Geos::Coordinate->new(1,0);
    my $c4 = Geo::Geos::Coordinate->new(1,2);

    my $ss1 = Geo::Geos::Noding::NodedSegmentString->new([$c1, $c2]);
    my $ss2 = Geo::Geos::Noding::NodedSegmentString->new([$c3, $c4]);

    my $li = Geo::Geos::Algorithm::LineIntersector->new(Geo::Geos::PrecisionModel->new);

    my $ia = Geo::Geos::Noding::IntersectionAdder->new($li);
    ok $ia;
    ok !$ia->isDone;
    is $ia->getLineIntersector, $li;

    $ia->processIntersections($ss1, 0, $ss2, 0);
    ok $li->hasIntersection;
    ok !$ia->isDone; # always false

    ok $ia->hasProperIntersection;
    ok $ia->hasIntersection;
    ok $ia->hasProperInteriorIntersection;
    ok $ia->hasInteriorIntersection;
};

done_testing;
