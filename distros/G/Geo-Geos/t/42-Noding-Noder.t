use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::Coordinate;
use Geo::Geos::PrecisionModel;
use Geo::Geos::Noding::NodedSegmentString;
use Geo::Geos::Noding::IteratedNoder;
use Geo::Geos::Noding::ScaledNoder;
use Geo::Geos::Noding::SinglePassNoder;
use Geo::Geos::Noding::SimpleNoder;
use Geo::Geos::Noding::SimpleSnapRounder;

subtest "Noder" => sub {
    my $pm1 = Geo::Geos::PrecisionModel->new;
    subtest "IteratedNoder" => sub {
        my $c1 = Geo::Geos::Coordinate->new(0,1);
        my $c2 = Geo::Geos::Coordinate->new(2,1);
        my $c3 = Geo::Geos::Coordinate->new(1,0);
        my $c4 = Geo::Geos::Coordinate->new(1,2);

        my $ss1 = Geo::Geos::Noding::NodedSegmentString->new([$c1, $c2]);
        my $ss2 = Geo::Geos::Noding::NodedSegmentString->new([$c3, $c4]);

        my $n = Geo::Geos::Noding::IteratedNoder->new(Geo::Geos::PrecisionModel->new);
        $n->setMaximumIterations(10);
        $n->computeNodes([$ss1, $ss2]);
        my $substr = $n->getNodedSubstrings;
        ok $substr;
        is scalar(@$substr), 4;

        subtest "ScaledNoder" => sub {
            my $n;
            subtest "safety check for IteratedNoder" => sub {
                $n = Geo::Geos::Noding::IteratedNoder->new(Geo::Geos::PrecisionModel->new);
                ok $n;
            };

            my $sn = Geo::Geos::Noding::ScaledNoder->new($n, 5, 4, 3);
            ok $sn;
            ok !$sn->isIntegerPrecision;

            my $ss1 = Geo::Geos::Noding::NodedSegmentString->new([$c1, $c2, $c3, $c4]);
            $sn->computeNodes([$ss1]);
            my $substr = $sn->getNodedSubstrings;
            ok $substr;
            is scalar(@$substr), 3;
            like $substr->[-1]->toString, qr/\QLINESTRING(1 1, 1 2)\E/;
        };
    };

    subtest "SimpleNoder" => sub {
        my $c1 = Geo::Geos::Coordinate->new(0,1);
        my $c2 = Geo::Geos::Coordinate->new(2,1);
        my $c3 = Geo::Geos::Coordinate->new(1,0);
        my $c4 = Geo::Geos::Coordinate->new(1,2);

        my $li = Geo::Geos::Algorithm::LineIntersector->new($pm1);
        my $ia = Geo::Geos::Noding::IntersectionAdder->new($li);
        my $sn = Geo::Geos::Noding::SimpleNoder->new($ia);
        ok $sn;

        my $ss1 = Geo::Geos::Noding::NodedSegmentString->new([$c1, $c2, $c3, $c4]);
        $sn->computeNodes([$ss1]);
        my $substr = $sn->getNodedSubstrings;
        ok $substr;
        is scalar(@$substr), 3;
        like $substr->[-1]->toString, qr/\QLINESTRING(1 1, 1 2)\E/;
    };

    subtest "SimpleSnapRounder" => sub {
        my $pm2 = Geo::Geos::PrecisionModel->new(2.0);

        my $c1 = Geo::Geos::Coordinate->new(0,1);
        my $c2 = Geo::Geos::Coordinate->new(2,1);
        my $c3 = Geo::Geos::Coordinate->new(1,0);
        my $c4 = Geo::Geos::Coordinate->new(1,2);

        my $ssr = Geo::Geos::Noding::SimpleSnapRounder->new($pm2);
        ok $ssr;

        my $ss1 = Geo::Geos::Noding::NodedSegmentString->new([$c1, $c2, $c3, $c4]);
        $ssr->computeNodes([$ss1]);
        my $substr = $ssr->getNodedSubstrings;
        is scalar(@$substr), 4;
        like $substr->[-1]->toString, qr/\QLINESTRING(1 1, 1 2)\E/;

        my $ss2 = Geo::Geos::Noding::NodedSegmentString->new([$c1, $c2]);
        $ssr->computeVertexSnaps([$ss2]);
        is scalar(@{ $ssr->getNodedSubstrings }), 4;

        subtest "safety checks" => sub {
            my $ssr;
            {
                $ssr = Geo::Geos::Noding::SimpleSnapRounder->new($pm2);
            };
            ok $ssr;
            $ssr->computeNodes([$ss1]);
            $ssr->computeVertexSnaps([$ss2]);
            is scalar(@{ $ssr->getNodedSubstrings }), 4;
        };
    };

};


done_testing;
