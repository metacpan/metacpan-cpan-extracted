use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount');


{
    ok(my $sa = Finance::StockAccount->new(), 'Instantiated new StockAccount object.');
    my $atHash1 = {
        symbol          => 'GOOGL',
        dateString      => '20140220T093800Z',
        action          => 'buy',
        quantity        => 4,
        price           => 538,
        commission      => 10,
    };
    my $atHash2 = {
        symbol          => 'GOOGL',
        dateString      => '20140408T142600Z',
        action          => 'sell',
        quantity        => 4,
        price           => 569,
        commission      => 10,
    };
    my $atHash3 = { # 2836
        symbol          => 'INTC',
        dateString      => '20130427T120600Z',
        action          => 'buy',
        quantity        => 100,
        price           => 28.26,
        commission      => 10,
    };
    my $atHash4 = { # 3296
        symbol          => 'INTC',
        dateString      => '20140302T164500Z',
        action          => 'sell',
        quantity        => 100,
        price           => 33.06,
        commission      => 10,
    };
    ok($sa->stockTransaction($atHash1), 'Added new stock transaction.');
    ok(my $at = Finance::StockAccount::AccountTransaction->new($atHash2), 'Created new AccountTransaction object.');
    ok($sa->addAccountTransactions([$at]), 'Added $at object.');
    ok($sa->stockTransaction($atHash3), 'Added new stock transaction (3).');
    ok($sa->stockTransaction($atHash4), 'Added new stock transaction (4).');
    is($sa->numberExcluded(), 0, 'Got zero excluded transactions as expected.');
    is($sa->profit(), 564, 'Got expected profit.');
    is($sa->maxCashInvested(), 4998, 'Got expected maximum cash invested at once.');
    ok($sa->profitOverOutlays() =~ /^0\.112/, 'Got expected return on investment.');
    ok($sa->profitOverMaxCashInvested() =~ /^0\.1128/, 'Got expected profit over max cash invested.');
    ok($sa->profitOverYears() =~ /^595\./, 'Got expected profit over years.');
    ok($sa->profitOverMaxCashInvestedOverYears() =~ /^0\.119/, 'Got expected mean annual profitOverOutlays.');
    is($sa->commissions(), 40, 'Got expected commissions.');
    is($sa->numberOfTrades(), 4, 'Got expected number of trades.');
    is($sa->regulatoryFees(), 0, 'Got expected regulatory fees.');
    ok($sa->skipStocks(qw(GOOGL)), 'Add GOOGL to skipstocks list.');
    is($sa->numberExcluded(), 2, 'Got two excluded transactions as expected when skipping GOOGL.');
    is($sa->profit(), 460, 'Got expected profit -- skipping GOOGL.');
    ok($sa->resetSkipStocks(), 'Reset skip stocks.');
    ok(!defined($sa->skipStocks()), 'Skip stocks now returns undef.');
    is($sa->profit(), 564, 'Including GOOGL again, got expected profit.');
    ok($sa->skipStocks(qw(GOOGL)), 'Added GOOGL back onto skipstocks list.');
    ok($sa->skipStocks(qw(INTC AMD)), 'Added INTC and AMD to skipstocks list.');
    ok(!$sa->profit(), 'Correctly failed to get profit when all stocks were skipped.');
    is(join('', $sa->skipStocks()), join('', sort qw(GOOGL INTC AMD)), 'Got expected skipStocks list.');
    is($sa->numberExcluded(), 4, 'Got expected number of excluded transactions when all stocks were skipped.');
}

{
    ok(my $sa = Finance::StockAccount->new(), 'Instantiated new StockAccount object.');
    my $atHash1 = {};
    ok(!$sa->stockTransaction($atHash1), 'Correctly failed to add empty stock transaction.');
    my $tm = Time::Moment->from_string('20120902T214500Z');
    $atHash1->{tm} = $tm;
    ok(!$sa->stockTransaction($atHash1), 'Correctly failed to add stock transaction containing only a date.');
    $atHash1->{symbol} = 'OOO';
    ok(!$sa->stockTransaction($atHash1), 'Correctly failed to add stock transaction containing only a date and a symbol.');
    $atHash1->{action} = 'short';
    ok(!$sa->stockTransaction($atHash1), 'Correctly failed to add stock transaction containing only a date, symbol, and action.');
    $atHash1->{quantity} = 5;
    ok(!$sa->stockTransaction($atHash1), 'Correctly failed to add stock transaction containing only a date, symbol, action, and quantity.');
    $atHash1->{price} = 0;
    ok(!$sa->stockTransaction($atHash1), 'Correctly failed to add stock transaction containing only a date, symbol, action, quantity, and zero price.');
    $atHash1->{price} = 5;
    ok($sa->stockTransaction($atHash1), 'Was finally able to add my stock transaction!');
}

{
    my $atHash = {
        symbol          => 'AAA',
        dateString      => '20120421T193800Z',
        action          => 'buy',
        quantity        => 200,
        price           => 0,
        commission      => 0,
    };
    ok(my $sa = Finance::StockAccount->new(), 'Instantiated new StockAccount object.');
    ok(!$sa->stockTransaction($atHash), 'Correctly failed to add stock transaction with price 0.');
    ok($sa = Finance::StockAccount->new({allowZeroPrice => 1}), 'Instantiated new StockAccount object with allowZeroPrice option turned on.');
    ok($sa->stockTransaction($atHash), 'Correctly added stock transaction with price 0 when allowZeroPrice set.');
    ok($sa->allowZeroPrice(), 'Got allowZeroPrice setting.');
    ok($sa->allowZeroPrice(0), 'Set allowZeroPrice setting.');
    ok(!$sa->allowZeroPrice(), 'Got value I set it to.');
}
{
    my $buy1 = {        #  -$2010.00
        symbol          => 'AAA',
        dateString      => '20120421T193800Z',
        action          => 'buy',
        quantity        => 100,
        price           => 20,
        commission      => 10,
    };
    my $sell1 = {       # +$1090
        symbol          => 'AAA',
        dateString      => '20120422T193800Z',
        action          => 'sell',
        quantity        => 50,
        price           => 22,
        commission      => 10,
    };
    my $sell2 = {       # +$1190
        symbol          => 'AAA',
        dateString      => '20120423T193800Z',
        action          => 'sell',
        quantity        => 50,
        price           => 24,
        commission      => 10,
    };
    ok(my $sa = Finance::StockAccount->new(), 'Created new stock account.');
    ok($sa->stockTransaction($buy1), 'Added buy1 transaction.');
    ok($sa->stockTransaction($sell1), 'Added sell1 transaction.');
    is($sa->commissions(), 15, 'Got expected commissions after first sale.');
    is($sa->profit(), 85, 'Got expected profit from just first sale.');
    ok($sa->stockTransaction($sell2), 'Added sell2 transaction.');
    is($sa->profit(), 270, 'Got expected total profit.');
}
{
    my $buy = {
        symbol          => 'CCC',
        dateString      => '20140521T193800Z',
        action          => 'buy',
        quantity        => 100,
        price           => 40,
        commission      => 10,
    };
    my $sell = {
        symbol          => 'CCC',
        dateString      => '20141006T194800Z',
        action          => 'sell',
        quantity        => 25,
        price           => 42,
        commission      => 10,
    };
    ok(my $sa = Finance::StockAccount->new(), 'Created new stock account.');
    ok($sa->stockTransaction($buy), 'Added buy transaction.');
    ok($sa->stockTransaction($sell), 'Added partial sell transaction.');
    is($sa->numberOfTrades(), 2, 'Got expected number of trades.');
    is($sa->numberExcluded(), 0, 'Got expected number excluded.');
}
{
    my $buy = {
        symbol          => 'DDD',
        dateString      => '20140511T193800Z',
        action          => 'buy',
        quantity        => 25,
        price           => 40,
        commission      => 10,
    };
    my $sell = {
        symbol          => 'DDD',
        dateString      => '20140916T194800Z',
        action          => 'sell',
        quantity        => 100,
        price           => 42,
        commission      => 10,
    };
    ok(my $sa = Finance::StockAccount->new(), 'Created new stock account.');
    ok($sa->stockTransaction($buy), 'Added buy transaction.');
    ok($sa->stockTransaction($sell), 'Added sale of more shares than I bought.');
    is($sa->numberOfTrades(), 2, 'Got expected number of trades.');
    is($sa->numberExcluded(), 0, 'Got expected number excluded.');
}
{
    my $buy = {
        symbol          => 'EEE',
        dateString      => '20140301T193800Z',
        action          => 'buy',
        quantity        => 100,
        price           => 40,
        commission      => 10,
    };
    ok(my $sa = Finance::StockAccount->new(), 'Created new stock account.');
    ok($sa->stockTransaction($buy), 'Added buy transaction.');
    is($sa->numberOfTrades(), 0, 'Got expected number of trades.');
    is($sa->numberExcluded(), 1, 'Got expected number excluded.');
}





done_testing();
