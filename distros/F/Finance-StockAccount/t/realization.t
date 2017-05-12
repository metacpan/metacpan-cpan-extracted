use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount::Realization');

my $print = 1;

my $initAt1 = {
    symbol          => 'ESI',
    action          => 'buy',
    price           => 7.89,
    quantity        => 100,
    commission      => 10,
};
my $initAt2 = {
    symbol          => 'ESI',
    action          => 'buy',
    price           => 6.50,
    quantity        => 200,
    commission      => 10,
};
my $initAt3 = {
    symbol          => 'ESI',
    action          => 'sell',
    price           => 8.25,
    quantity        => 300,
    commission      => 10,
};
ok(my $at1 = Finance::StockAccount::AccountTransaction->new($initAt1), 'Created account transaction object.');
ok(my $at2 = Finance::StockAccount::AccountTransaction->new($initAt2), 'Created account transaction object.');
ok(my $at3 = Finance::StockAccount::AccountTransaction->new($initAt3), 'Created account transaction object.');

{
    ok(my $at1 = Finance::StockAccount::AccountTransaction->new($initAt1), 'Created account transaction object.');
    ok(my $at2 = Finance::StockAccount::AccountTransaction->new($initAt2), 'Created account transaction object.');
    ok(my $at3 = Finance::StockAccount::AccountTransaction->new($initAt3), 'Created account transaction object.');
    ok(my $acquisition1 = Finance::StockAccount::Acquisition->new($at1, $initAt1->{quantity}), 'Instantiated at1 Acquisition object.');
    ok(my $acquisition2 = Finance::StockAccount::Acquisition->new($at2, $initAt2->{quantity}), 'Instantiated at2 Acquisition object.');
    my $initRealization = {
        stock           => $at1->stock(),
        divestment      => $at3,
    };
    ok(my $realization = Finance::StockAccount::Realization->new($initRealization), 'Instantiated Realization object.');
    ok($realization->addAcquisition($acquisition1), 'Added first acquisition.');
    ok($realization->addAcquisition($acquisition2), 'Added second acquisition.');
    is($realization->acquisitionCount(), 2, 'Received expected acquisition count.');
    ok(my $profit = $realization->realized(), 'Got realized profit.');
    my $expectedReturn = $at1->cashEffect() + $at2->cashEffect + $at3->cashEffect();
    is($profit, $expectedReturn, "Received expected profit number: $profit.\n");
    ok(my $headerString = $realization->headerString(), 'Got header string.');
    ok(my $string = $realization->string(), 'Got realization as string.');
    if ($print) {
        print "\n", $headerString, "\n", $string, "\n";
    }
}
{
    $at3->quantity(250);
    ok(my $acquisition1 = Finance::StockAccount::Acquisition->new($at1, 50), 'Instantiated modified at1 Acquisition object.');
    ok(my $acquisition2 = Finance::StockAccount::Acquisition->new($at2, 200), 'Instantiated modified at2 Acquisition object.');
    my $initRealization = {
        stock           => $at1->stock(),
        divestment      => $at3,
    };
    ok(my $realization = Finance::StockAccount::Realization->new($initRealization), 'Instantiated "250" Realization object.');
    ok($realization->addAcquisition($acquisition1), 'Added first acquisition for 100 shares.');
    ok($realization->addAcquisition($acquisition2), 'Added second acquisition for 200 shares.');
    ok(my $profit = $realization->realized(), 'Realized "250" realization.');
    my $expectedReturn = ($at1->cashEffect()/2) + $at2->cashEffect + $at3->cashEffect();
    is($profit, $expectedReturn, "Received expected '250' profit number: $profit.\n");
}



done_testing();
