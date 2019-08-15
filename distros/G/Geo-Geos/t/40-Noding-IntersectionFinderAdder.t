use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::PrecisionModel;
use Geo::Geos::Noding::NodedSegmentString;
use Geo::Geos::Noding::IntersectionAdder;

subtest "IntersectionFinderAdder" => sub {
    my $c4 = Geo::Geos::Coordinate->new(1,2);

    my $li = Geo::Geos::Algorithm::LineIntersector->new(Geo::Geos::PrecisionModel->new);

    my $iaf = Geo::Geos::Noding::IntersectionFinderAdder->new($li, [$c4]);
    ok $iaf;
    ok !$iaf->isDone; # always false
    is_deeply $iaf->getInteriorIntersections, [$c4];
};

done_testing;
