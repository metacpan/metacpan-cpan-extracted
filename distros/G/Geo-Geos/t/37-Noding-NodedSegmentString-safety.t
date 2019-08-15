use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::Noding::NodedSegmentString;

subtest "NodedSegmentString" => sub {
    my $c4 = Geo::Geos::Coordinate->new(9,1.5);

    my $n;
    {
        my $c1 = Geo::Geos::Coordinate->new(1,2);
        my $c2 = Geo::Geos::Coordinate->new(5,2);
        my $c3 = Geo::Geos::Coordinate->new(7,1);
        $n =  Geo::Geos::Noding::NodedSegmentString
                ->new([$c1, $c2, $c3])
                ->addIntersectionNode($c4, 1);
        is $n->segmentIndex, 1;
    };
    ok $n->isInterior;
    is $n->segmentIndex, 1;
    my $c = $n->coord;
    ok $c;
    isa_ok($c, 'Geo::Geos::Coordinate');
    ok $n;
};


done_testing;
