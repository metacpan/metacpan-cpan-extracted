use strict;
use warnings;

use Test::More;
use Time::Moment;

use_ok('Finance::StockAccount::Set');

my $print = 1;

{

    ok(my $tm1 = Time::Moment->from_string("20120131T000000Z"), 'Instantiated tm1 Time::Moment object.');
    ok(my $tm4 = Time::Moment->from_string("20120819T000000Z"), 'Instantiated tm4 Time::Moment object.');
    ok(my $tm5 = Time::Moment->from_string("20120921T000000Z"), 'Instantiated tm5 Time::Moment object.');

    my $initAt1 = {
        symbol          => 'AMD',
        tm              => $tm1,
        action          => 'buy',
        price           => 3.98,
        quantity        => 200,
        commission      => 10,
    };
    my $initAt2 = {
        symbol          => 'AMD',
        dateString      => "20120225T000000Z",
        action          => 'buy',
        price           => 3.74,
        quantity        => 300,
        commission      => 10,
    };
    my $initAt3 = {
        symbol          => 'AMD',
        dateString      => "20120311T000000Z",
        action          => 'buy',
        price           => 3.45,
        quantity        => 500,
        commission      => 10,
    };
    my $initAt4 = {
        symbol          => 'AMD',
        dateString      => $tm4,
        action          => 'sell',
        price           => 4.05,
        quantity        => 1000,
        commission      => 10,
    };
    my $initAt5 = {
        symbol          => 'AMD',
        dateString      => $tm5,
        action          => 'buy',
        price           => 3.89,
        quantity        => 200,
        commission      => 10,
    };

    ok(my $at1 = Finance::StockAccount::AccountTransaction->new($initAt1), 'Created account transaction 1.');
    ok(my $at2 = Finance::StockAccount::AccountTransaction->new($initAt2), 'Created account transaction 2.');
    ok(my $at3 = Finance::StockAccount::AccountTransaction->new($initAt3), 'Created account transaction 3.');
    ok(my $at4 = Finance::StockAccount::AccountTransaction->new($initAt4), 'Created account transaction 4.');
    ok(my $at5 = Finance::StockAccount::AccountTransaction->new($initAt5), 'Created account transaction 5.');

    ok(my $set = Finance::StockAccount::Set->new([$at2, $at5, $at4, $at3, $at1]), 'Instantiated new Set object.');
    ok($set->printTransactionDates(), 'Print transaction dates.');
    ok($set->accountSales(), 'Accounted for sales.');
    is($set->transactionCount(), 4, 'Got expected transaction count.');
    is($set->unrealizedTransactionCount(), 1, 'Got expected count of unrealized transactions.');
    is($set->totalOutlays(), 3673, 'Cost (totalOutlays) as expected.');
    is($set->totalRevenues(), 4040, 'Benefit (revenue) as expected.');
    is($set->profit(), 367, 'Profit as expected.');
    ok($set->profitOverOutlays() =~ /^0\.0999/, 'Profit over outlays as expected.');
    ok($set->startDate() == $tm1, 'Got expected start date.');
    ok($set->endDate() == $tm4, 'Got expected end date.');
    is(scalar(@{$set->unrealizedTransactions()}), 1, 'One unrealized transaction, as expected.');
    is($set->unrealizedTransactionCount(), 1, 'Tailored method also returns one unrealized transaction.');
    ok(my $realizationsString = $set->realizationsString(), 'Got realizations string.');
    if ($print) {
        print $realizationsString;
        print $set->oneLinerHeader(), $set->oneLiner(), $set->oneLinerSpacer();
    }
}

{
    my $initAt1 = {
        symbol          => 'AAA',
        dateString      => "20120721T182400Z",
        action          => 'buy',
        price           => 3.74,
        quantity        => 200,
        commission      => 10,
    };
    ok(my $at1 = Finance::StockAccount::AccountTransaction->new($initAt1), 'Created account transaction 1.');
    ok(my $stock = $at1->stock(), 'Got stock from AT object.');
    my $initAt2 = {
        stock           => $stock,
        dateString      => "20120815T141800Z",
        action          => 'buy',
        price           => 3.43,
        quantity        => 300,
        commission      => 10,
    };
    ok(my $at2 = Finance::StockAccount::AccountTransaction->new($initAt2), 'Created account transaction 2.');
    my $initAt3 = {
        stock           => $stock,
        dateString      => "20121006T135300Z",
        action          => 'sell',
        price           => 3.97,
        quantity        => 500,
        commission      => 10,
    };
    ok(my $at3 = Finance::StockAccount::AccountTransaction->new($initAt3), 'Created account transaction 3.');
    ok(my $set = Finance::StockAccount::Set->new([$at1, $at2, $at3]), 'Instantiated new Set object.');
    is($set->profit(), 178, 'Got expected profit.');

    ok($set->clearPastAccounting(), 'Cleared past accounting.');
    is($set->{stats}{profit}, 0, 'Found expected profit of 0 after stats clear.');

    my $tm1 = Time::Moment->from_string("20120601T000000Z");
    my $tm2 = Time::Moment->from_string("20121121T000000Z");
    ok($set->setDateLimit($tm1, $tm2), 'Set date limit.');
    is($set->profit(), 178, 'Got expected profit where date limit includes entire realization range.');
    
    ### adjusting date limit ending
    $tm2 = Time::Moment->from_string("20120731T000000Z");
    ok($set->setDateLimit($tm1, $tm2), 'Moved the date limit ending to early within the realization range.');
    ok($set->profit() < 10, 'Profit within expected range where date limit ends early in the realization range.');

    $tm2 = Time::Moment->from_string("20120820T000000Z");
    ok($set->setDateLimit($tm1, $tm2), 'Moved the date limit ending to later within the realization range.');
    my $profit = $set->profit();
    ok($profit > 10 && $profit < 60, 'Profit within expected range where date limit ends later in the realization range.');

    $tm2 = Time::Moment->from_string("20121005T000000Z");
    ok($set->setDateLimit($tm1, $tm2), 'Moved the date limit ending to near the end of the realization range.');
    $profit = $set->profit();
    ok($profit > 160 && $profit < 178, 'Profit within expected range where date limit ending is near the end of the realization range.');

    ### adjusting date limit start
    $tm1 = Time::Moment->from_string("20121005T000000Z");
    $tm2 = Time::Moment->from_string("20121121T000000Z");
    ok($set->setDateLimit($tm1, $tm2), 'Moved the date limit start to very late within the realization range.');
    ok($set->profit() < 10, 'Profit within expected range where date limit starts very late in the realization range.');

    $tm1 = Time::Moment->from_string("20120912T000000Z");
    ok($set->setDateLimit($tm1, $tm2), 'Moved the date limit start to near the middle within the realization range.');
    $profit = $set->profit();
    ok($profit > 70 && $profit < 100, 'Profit within expected range where date limit starts near the middle of the realization range.');

    $tm1 = Time::Moment->from_string("20120723T000000Z");
    ok($set->setDateLimit($tm1, $tm2), 'Moved the date limit start to near the beginning of the realization range.');
    $profit = $set->profit();
    ok($profit > 172 && $profit < 178, 'Profit within expected range where date limit starts near the beginning of the realization range.');

    ### date limit range is entirely within realization range
    $tm2 = Time::Moment->from_string("20121005T000000Z");
    ok($set->setDateLimit($tm1, $tm2), 'Moved the date limit end to near the end of the realization range.');
    $profit = $set->profit();
    ok($profit > 160  && $profit < 174, 'Profit within expected range where date limit range is entirely within and slightly smaller than realization range.');

    $tm1 = Time::Moment->from_string("20120808T000000Z");
    $tm2 = Time::Moment->from_string("20120929T000000Z");
    ok($set->setDateLimit($tm1, $tm2), 'Shrak the date limit range within the realization range.');
    $profit = $set->profit();
    ok($profit > 140  && $profit < 150, 'Profit within expected range.');

    $tm1 = Time::Moment->from_string("20120912T000000Z");
    $tm2 = Time::Moment->from_string("20120915T000000Z");
    ok($set->setDateLimit($tm1, $tm2), 'Shrank the date limit range within the realization range to quite small.');
    $profit = $set->profit();
    ok($profit > 4  && $profit < 16, 'Profit within expected range.');

    ### ranges don't overlap
    $tm1 = Time::Moment->from_string("20121007T000000Z");
    $tm2 = Time::Moment->from_string("20121121T000000Z");
    ok($set->setDateLimit($tm1, $tm2), 'Moved the date limit start to after the end of the realization range.');
    is($set->profit(), 0, 'Profit zero where date limit starts after the end of the realization range.');

    $tm1 = Time::Moment->from_string("20120521T090000Z");
    $tm2 = Time::Moment->from_string("20120715T230000Z");
    ok($set->setDateLimit($tm1, $tm2), 'Moved the date limit end to before the start of the realization range.');
    is($set->profit(), 0, 'Profit zero where date limit ends before the start of the realization range.');
}
{
    my $init = {
        symbol          => 'BBB',
        dateString      => "20130920T182400Z",
        action          => 'buy',
        price           => 3.74,
        quantity        => 200,
        commission      => 10,
    };
    ok(my $at = Finance::StockAccount::AccountTransaction->new($init), 'Created account transaction object.');
    ok(my $set = Finance::StockAccount::Set->new([$at]), 'Instantiated new Set object.');
    is($set->stale(), 1, 'Set is stale, as expected.');
    ok(!$set->accountSales(), 'Account sales returned false, as expected.');
    is($set->unrealizedTransactionCount(), 1, 'Got expected number of unrealized transactions.');
}



    



done_testing();
