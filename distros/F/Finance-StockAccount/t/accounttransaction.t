use strict;
use warnings;

use Test::More;

use_ok('Finance::StockAccount::AccountTransaction');

{
    my $init = {
        price       => 535.75,
        symbol      => 'AAPL',
        quantity    => 4,
        commission  => 10,
    };
    my $at = Finance::StockAccount::AccountTransaction->new($init);
    eval {
        $at->sell();
    };
    ok($@ =~ /^Action has not yet been set/, 'Received expected error getting action without setting action first.');
    ok($at->buy(1), 'Set action to buy.');
    ok($at->available(), "Shares are available.");
    ok($at->possiblePurchase('sell'), 'Transaction is a possible purchase.');
    is($at->accountShares(3), 3, 'Accounted expected number of shares.');
    is($at->available(), 1, 'Got expected number of available shares.');
    ok($at->possiblePurchase('sell'), 'Transaction is still a possible purchase.');
}



done_testing();


