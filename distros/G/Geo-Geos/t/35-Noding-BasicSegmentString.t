use 5.012;
use warnings;
use Test::Fatal;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::Noding::BasicSegmentString;

subtest "BasicSegmentString" => sub {
    my $c1 = Geo::Geos::Coordinate->new(1,2);
    my $c2 = Geo::Geos::Coordinate->new(5,2);
    my $c3 = Geo::Geos::Coordinate->new(7,1);

    my $seq = [$c1, $c2, $c3];
    my $ss = Geo::Geos::Noding::BasicSegmentString->new($seq);
    ok $ss;
    ok !$ss->isClosed;
    is $ss->size, 3;
    is $ss->getCoordinate(0), $c1;

    my $coords = $ss->getCoordinates;
    is_deeply $coords, $seq;

    like $ss->toString, qr/\QLINESTRING(1 2, 5 2, 7 1)\E/;
    is $ss->getSegmentOctant(0), 0;
};

done_testing;
