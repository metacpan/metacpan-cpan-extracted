use strict;
use warnings;

use Test::More;
use File::Spec;
use File::ShareDir qw(dist_file);

use Finance::StockAccount::Import::OptionsXpress;

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

my $allFile2014 = getFile('dlAllActivity201409.csv');
my $printAnnualStats = 0;
my $printQuarterlyStats = 0;
my $printMonthlyStats = 0;
my $printStatsString = 0;
my $printSets = 0;
my $printRealizations = 1;


{
    ok(my $ox = Finance::StockAccount::Import::OptionsXpress->new($allFile2014, -240), 'Created new OX object for all activity as of September 2014.');
    ok(my $sa = $ox->stockAccount(), 'Read file into stock account object.');
    ok($sa->profit() =~ /^9960\.08/, 'Got expected profit.');
    ok($sa->maxCashInvested() =~ /^15989\./, 'Got expected max cash invested.');
    ok($sa->profitOverOutlays() =~ /^0\.0964/, 'Got expected profit over outlays.');
    ok($sa->profitOverMaxCashInvested() =~ /^0\.62/, 'Got expected profit over max cash invested.');
    ok($sa->profitOverYears() =~ /^4259\./, 'Got expected profit over years.');
    ok($sa->profitOverMaxCashInvestedOverYears() =~ /^0\.26/, 'Got expected profit over max cash invested over years.');
    ok($sa->commissions() =~ /^976\.0/, 'Got expected commissions total.'); # old value 1038.2
    ok($sa->regulatoryFees() =~ /^2\.38/, 'Got expected regulatory fees total.'); # old value 2.42
    is($sa->otherFees(), 0, 'Got expected other fees total.');
    ok(my $annualStats = $sa->annualStats(), 'Calculated annual stats.');
    ok($annualStats->[0]{profit} =~ /^764\.5/, 'Got expected profit for 2012.');
    ok($annualStats->[1]{profit} =~ /^5871\.0/, 'Got expected profit for 2013.');
    ok($annualStats->[2]{profit} =~ /^3324\.4/, 'Got expected profit for 2014.');
    my $sumProfit = $annualStats->[0]{profit} + $annualStats->[1]{profit} + $annualStats->[2]{profit};
    ok($sumProfit =~ /^9960\./, 'Got expected total profit for all three years.');
    ok(my $quarterlyStats = $sa->quarterlyStats(), 'Calculated quarterly stats.');
    ok($quarterlyStats->[4]{maxCashInvested} =~ /^13326\./, 'Got expected maxCashInvested for the fifth quarterly stats calculation.');
    ok(my $statsString = $sa->statsString(), 'Got stats string.');
    ok(my $realizationsString = $sa->realizationsString(), 'Got realizations string.');

    ### Printing
    if ($printAnnualStats) {
        print "\n", $sa->annualStatsString();
    }
    if ($printQuarterlyStats) {
        print "\n", $sa->quarterlyStatsString();
    }
    if ($printMonthlyStats) {
        print "\n", $sa->monthlyStatsString();
    }
    if ($printStatsString) {
        print "\n", $statsString;
    }
    if ($printSets) {
        print "\n", $sa->summaryByStock();
    }
    if ($printRealizations) {
        print "\n", $realizationsString;
    }
}

done_testing();
