use strict;
use warnings;

use Test::More;
use File::Spec;
use File::ShareDir qw(dist_file);

sub getFile {
    my $name = shift;
    my $file;
    my $local = File::Spec->catfile('data', $name);
    if (-e $local) {
        $file = $local;
    }
    else {
        $file = dist_file('Finance-StockAccount', $name);
    }
    return $file;
}


{
    use Finance::StockAccount;

    # One (fake) trade a day for a week in January...
    my $sa = Finance::StockAccount->new();
    $sa->stockTransaction({ # total cost: 1000
        symbol          => 'AAA',
        dateString      => '20140106T150500Z', 
        action          => 'buy',
        quantity        => 198,
        price           => 5,
        commission      => 10,
    });
    $sa->stockTransaction({ # total cost: 1000
        symbol          => 'BBB',
        dateString      => '20140107T150500Z', 
        action          => 'buy',
        quantity        => 99,
        price           => 10,
        commission      => 10,
    });
    $sa->stockTransaction({ # total proceeds: 600 
        symbol          => 'AAA',
        dateString      => '20140108T150500Z', 
        action          => 'sell',
        quantity        => 100,
        price           => 6.10,
        commission      => 10,
    });
    $sa->stockTransaction({ # total proceeds: 1070
        symbol          => 'BBB',
        dateString      => '20140109T150500Z', 
        action          => 'sell',
        quantity        => 99,
        price           => 11,
        commission      => 19,
    });
    $sa->stockTransaction({ # total proceeds: 670
        symbol          => 'AAA',
        dateString      => '20140110T150500Z', 
        action          => 'sell',
        quantity        => 98,
        price           => 7,
        commission      => 16,
    });

    my $profit                      = $sa->profit();                    # 340
    my $maxCashInvestment           = $sa->maxCashInvested();           # 2000
    my $profitOverMaxCashInvested   = $sa->profitOverMaxCashInvested(); # 0.17
    my $profitOverOutlays           = $sa->profitOverOutlays();         # 0.17
    my $profitOverYears             = $sa->profitOverYears();           # 31046.25
    my $commissions                 = $sa->commissions();               # 65
    my $numberOfTrades              = $sa->numberOfTrades();            # 5

    is($profit, 340, 'Got expected profit.');
    is($maxCashInvestment, 2000, 'Got expected maxCashInvested.');
    is($profitOverOutlays, 0.17, 'Got expected profitOverOutlays.');
    is($profitOverMaxCashInvested, 0.17, 'Got expected profitOverMaxCashInvested.');
    is($profitOverYears, 31046.25, 'Got expected profit divided by years.  Doing pretty well for yourself!');
    is($commissions, 65, 'Got expected commissions.');
    is($numberOfTrades, 5, 'Got expected number of trades.');
}

{
    # Alternatively, you can export an activity file from your online brokerage account
    # and then import that.  Only works for OptionsXpress so far, more to come.

    use Finance::StockAccount::Import::OptionsXpress;
    my $file = getFile('dlAmdActivity.csv');

    my $ox = Finance::StockAccount::Import::OptionsXpress->new($file);
    my $sa = $ox->stockAccount();
    my $profit = $sa->profit();     # 2803.63


    is($profit, 2803.63, 'Got expected profit from AMD activity file.');
}
 



done_testing();

# Any Time::Moment recognized date string, 
# in this case January 24, 2014 at 15:05 (3:05 PM) UTC
