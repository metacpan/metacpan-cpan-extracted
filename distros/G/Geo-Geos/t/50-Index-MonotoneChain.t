use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::Envelope;

use Geo::Geos::Index::MonotoneChain qw/getChains/;
use Geo::Geos::Index::MonotoneChainOverlapAction;

subtest "MonotoneChain, MonotoneChainOverlapAction, MonotoneChainBuilder" => sub {
    my $c1 = Geo::Geos::Coordinate->new(0,2);
    my $c2 = Geo::Geos::Coordinate->new(1,2);
    my $c3 = Geo::Geos::Coordinate->new(2,2);
    my $c4 = Geo::Geos::Coordinate->new(3,1);
    my $c5 = Geo::Geos::Coordinate->new(4,1);
    my $c6 = Geo::Geos::Coordinate->new(5,1);
    my $c7 = Geo::Geos::Coordinate->new(6,0);
    my $c8 = Geo::Geos::Coordinate->new(7,0);

    my $list = [$c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8];
    my $mc = Geo::Geos::Index::MonotoneChain->new($list, 0, 7);
    ok $mc;
    is $mc->getStartIndex, 0;
    is $mc->getEndIndex, 7;

    $mc->setId(1234);
    is $mc->getId, 1234;

    my $l2 = $mc->getCoordinates;
    is_deeply $l2, $list;

    my $ls = $mc->getLineSegment(0);
    ok $ls;
    is $ls->toString, 'LINESEGMENT(0 2,1 2)';

    my $e = $mc->getEnvelope;
    ok $e;
    is $e->toString, 'Env[0:7,0:2]';
    my $mc2 = Geo::Geos::Index::MonotoneChain->new([$c5, $c6], 0, 1);

    my $mcoa = Geo::Geos::Index::MonotoneChainOverlapAction->new;
    $mc->computeOverlaps($mc2, $mcoa);
    ok $mcoa;
    is $mcoa->tempEnv1->toString, 'Env[5:7,0:1]';
    is $mcoa->tempEnv2->toString, 'Env[4:5,1:1]';

    $mcoa->overlap($mc, 0, $mc2, 1);
    $mcoa->overlap($ls, $mc2->getLineSegment(9));
    is $mcoa->tempEnv1->toString, 'Env[5:7,0:1]';
    is $mcoa->tempEnv2->toString, 'Env[4:5,1:1]';

    my $chains = getChains($list);
    ok $chains;
    is scalar(@$chains), 5;
};

done_testing;
