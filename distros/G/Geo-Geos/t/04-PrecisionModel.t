use 5.012;
use warnings;
use Test::More;
use Test::Warnings;

use Geo::Geos::PrecisionModel qw/TYPE_FIXED TYPE_FLOATING TYPE_FLOATING_SINGLE/;

subtest "c-tors" => sub {
    my $pm1 = Geo::Geos::PrecisionModel->new;
    ok $pm1, "default ctor";
    is $pm1->getType, TYPE_FLOATING;

    my $pm2 = Geo::Geos::PrecisionModel->new(TYPE_FLOATING);
    ok $pm2, "floating ctor";
    ok $pm2->isFloating;
    is $pm2->getType, TYPE_FLOATING;

    my $pm3 = Geo::Geos::PrecisionModel->new(TYPE_FLOATING_SINGLE);
    ok $pm3, "single floating ctor";
    ok $pm3->isFloating;
    is $pm3->getType, TYPE_FLOATING_SINGLE;

    my $pm4 = Geo::Geos::PrecisionModel->new(TYPE_FIXED);
    ok $pm4, "fixed ctor";
    ok !$pm4->isFloating;
    is $pm4->getType, TYPE_FIXED;

    my $pm5 = Geo::Geos::PrecisionModel->new(2.0);
    ok $pm5;
    ok !$pm5->isFloating;
    is $pm5->getScale(), 2.0;
    is $pm5->getType, TYPE_FIXED;

    my $pm6 = Geo::Geos::PrecisionModel->new(2.1, 1.1, 1.5);
    ok $pm6;
    ok !$pm6->isFloating;
    ok abs($pm6->getScale() - 2.1) < 0.000001;
    is $pm6->getType, TYPE_FIXED;
};

subtest "toString, getMaximumSignificantDigits, makePrecise " => sub {
    my $pm = Geo::Geos::PrecisionModel->new;
    is $pm->toString, "Floating";
    is $pm->getMaximumSignificantDigits(), 16;

    ok abs($pm->makePrecise(1.000001)- 1.000001) < 0.000001;
};

subtest "compareTo" => sub {
    my $pm1 = Geo::Geos::PrecisionModel->new(TYPE_FLOATING);
    my $pm2 = Geo::Geos::PrecisionModel->new(TYPE_FLOATING_SINGLE);
    is $pm1->compareTo($pm1), 0;
    is $pm1->compareTo($pm2), 1;
    is $pm2->compareTo($pm1), -1;
};

done_testing;

