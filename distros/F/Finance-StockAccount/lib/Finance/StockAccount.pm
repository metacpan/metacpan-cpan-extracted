package Finance::StockAccount;

our $VERSION = '0.01';

use strict;
use warnings;

use Carp;
use POSIX;

use Finance::StockAccount::Set;
use Finance::StockAccount::AccountTransaction;
use Finance::StockAccount::Stock;



### Class definition
sub new {
    my ($class, $options) = @_;
    my $self = {
        sets                => {},
        skipStocks          => {},
        stats               => $class->getNewStatsHash(),
        allowZeroPrice      => 0,
        verbose             => 1,
    };
    if ($options and exists($options->{allowZeroPrice}) and $options->{allowZeroPrice}) {
        $self->{allowZeroPrice} = 1;
    }
    return bless($self, $class);
}

sub getNewStatsHash {
    return {
        stale                       => 1,
        startDate                   => undef,
        endDate                     => undef,
        maxCashInvested             => 0,
        totalOutlays                => 0,
        totalRevenues               => 0,
        profit                      => 0,
        profitOverOutlays           => 0,
        profitOverMaxCashInvested   => 0,
        profitOverYears             => 0,
        pomciOverYears              => 0,
        commissions                 => 0,
        regulatoryFees              => 0,
        otherFees                   => 0,
        numberOfTrades              => 0,
        numberExcluded              => 0,
        annualRatio                 => 0,
        annualStats                 => undef,
        annualStatsStale            => 1,
        quarterlyStats              => undef,
        quarterlyStatsStale         => 1,
        monthlyStats                => undef,
        monthlyStatsStale           => 1,
    };
}


### For convenience text output
my $statsKeyHeadings = [qw(
    Outlays Revenues MaxInvested Profit OverOut
    OverInvested Commiss RegFees OthFees NumTrades
)];
my $statsKeyHeadingsPattern = "%12s %12s %12s %12s %7s %12s %9s %7s %7s %9s";

my $statsKeys = [qw(
    totalOutlays              totalRevenues maxCashInvested profit    profitOverOutlays
    profitOverMaxCashInvested commissions   regulatoryFees  otherFees numberOfTrades
)];
my $statsKeysPattern = "%12.2f %12.2f %12.2f %12.2f %7.2f %12.2f %9.2f %7.2f %7.2f %9d";

my $statsLinesArray = [
        'First Trade Date'                  => 'startDate'                  => '%35s',
        'Last Trade Date'                   => 'endDate'                    => '%35s',
        'Maximum Cash Invested at Once'     => 'maxCashInvested'            => '%35.2f',
        'Sum Outlays'                       => 'totalOutlays'               => '%35.2f',
        'Sum Revenues'                      => 'totalRevenues'              => '%35.2f',
        'Total Profit'                      => 'profit'                     => '%35.2f',
        'Profit Over Years'                 => 'profitOverYears'            => '%35.2f',
        'Profit Over Sum Outlays'           => 'profitOverOutlays'          => '%35.2f',
        'Profit Over Max Cash Invested'     => 'profitOverMaxCashInvested'  => '%35.2f',
        'The Above (^) Over Years'          => 'pomciOverYears'             => '%35.2f',
        'Total Commissions'                 => 'commissions'                => '%35.2f',
        'Total Regulatory Fees'             => 'regulatoryFees'             => '%35.2f',
        'Total Other Fees'                  => 'otherFees'                  => '%35.2f',
        'Num Trades Included in Stats'      => 'numberOfTrades'             => '%35d',
        'Num Trades Excluded from Stats'    => 'numberExcluded'             => '%35d',
];


### Methods
sub stale {
    my ($self, $assertion) = @_;
    my $stats = $self->{stats};
    if (defined($assertion)) {
        if ($assertion == 1 or $assertion == 0) {
            if ($assertion) {
                my $value = 1;
                $stats->{stale}               = $value;
                $stats->{annualStatsStale}    = $value;
                $stats->{quarterlyStatsStale} = $value;
                $stats->{monthlyStatsStale}   = $value;
            }
            else {
                $stats->{stale} = 0;
            }
            return 1;
        }
        else {
            croak "Method 'stale' only accepts assertions in the form of 1 or 0 -- $assertion is not valid.";
        }
    }
    else {
        return $stats->{stale};
    }
}

sub allowZeroPrice {
    my ($self, $allowZeroPrice) = @_;
    if (defined($allowZeroPrice)) {
        $self->{allowZeroPrice} = $allowZeroPrice ? 1 : 0;
        return 1;
    }
    else {
        return $self->{allowZeroPrice};
    }
}

sub getSet {
    my ($self, $hashKey) = @_;
    if (exists($self->{sets}{$hashKey})) {
        return $self->{sets}{$hashKey};
    }
    else {
        return undef;
    }
}

sub getSetFiltered {
    my ($self, $hashKey) = @_;
    if ($self->{skipStocks}{$hashKey}) {
        return undef;
    }
    elsif (exists($self->{sets}{$hashKey})) {
        my $set = $self->{sets}{$hashKey};
        if ($set->stale()) {
            $set->accountSales();
        }
        if ($set->realizationCount() > 0) {
            return $set;
        }
        else {
            return undef;
        }
    }
    else {
        return undef;
    }
}

sub getFilteredSets {
    my $self = shift;
    my @sets;
    foreach my $hashKey (sort keys %{$self->{sets}}) {
        my $set = $self->getSetFiltered($hashKey);
        $set and push(@sets, $set);
    }
    return \@sets;
}

sub addToSet {
    my ($self, $at) = @_;
    if (ref($at) and ref($at) eq 'Finance::StockAccount::AccountTransaction') {
        my $hashKey = $at->hashKey();
        my $set = $self->getSet($hashKey);
        my $status;
        if ($set) {
            $status = $set->add([$at]);
        }
        else {
            $set = Finance::StockAccount::Set->new([$at]);
            $self->{sets}{$hashKey} = $set;
            $status = $set;
        }
        $status and $self->stale(1);
        return $status;
    }
    else {
        warn "Method addToSet requires a valid AccountTransaction object.\n";
        return 0;
    }
}

sub addAccountTransactions {
    my ($self, $accountTransactions) = @_;
    if (ref($accountTransactions) and ref($accountTransactions) eq 'ARRAY') {
        my $added = 0;
        foreach my $at (@$accountTransactions) {
            $self->addToSet($at) and $added++;
        }
        $added and $self->stale(1);
        return $added;
    }
    else {
        warn "Method addAccountTransactions requiers a reference to an array of AccountTransaction objects.\n";
        return 0;
    }
}

sub stockTransaction {
    my ($self, $init) = @_;
    my $helpString = q{  Please see 'perldoc Finance::StockAccount'.};
    if (!(exists($init->{tm}) or exists($init->{dateString}))) {
        carp "A date is required to add a stock transaction, using either the 'tm' key or the 'dateString' key.$helpString";
        return 0;
    }
    elsif (!(exists($init->{stock}) or exists($init->{symbol}))) {
        carp "A stock is required to add a transaction, using either the 'stock' key or the 'symbol' key.$helpString";
        return 0;
    }
    elsif (!(exists($init->{action}) and (grep { $_ eq $init->{action} } qw(buy sell short cover)))) {
        carp "To add a transaction, you must specify an action, one of 'buy', 'sell', 'short', or 'cover'.$helpString";
        return 0;
    }
    elsif (!(exists($init->{quantity}) and $init->{quantity} =~ /[0-9]/ and $init->{quantity} > 0)) {
        carp "To add a transaction, you must specify a numeric quantity, and it must be greater than zero.$helpString";
        return 0;
    }
    elsif (!(exists($init->{price}) and $init->{price} =~ /[0-9]/)) {
        carp "To add a transaction, you must specify a price, and it must be numeric.$helpString";
        return 0;
    }
    elsif ($init->{price} <= 0 and !$self->{allowZeroPrice}) {
        carp "To add a transaction, price must be greater than zero.  By default, prices zero or lower are treated as suspect and not included in calculations.\nYou may override this default behavior by setting 'allowZeroPrice' to true.$helpString";
        return 0;
    }
    else {
        if (exists($init->{stock}) and (exists($init->{symbol}) or exists($init->{exchange}))) {
            carp "To add a transaction, you may specify a Finance::StockAccount::Stock object, or a symbol (optionally with an exchange).\nYou need not specify both.  Proceeding on the assumption that the stock object is intentional and the symbol/exchange are accidental...";
            exists($init->{symbol}) and delete($init->{symbol});
            exists($init->{exchange}) and delete($init->{exchange});
        }
        my $at = Finance::StockAccount::AccountTransaction->new($init);
        if ($at) {
            return $self->addToSet($at);
        }
        else {
            carp "Unable to create AccountTransaction object with those parameters.\n";
            return 0;
        }
    }
}

sub skipStocks {
    my ($self, @skipStocks) = @_;
    my $count = 0;
    if (scalar(@skipStocks)) {
        foreach my $stock (@skipStocks) {
            $self->{skipStocks}{$stock} = 1;
        }
        $self->stale(1);
        return 1;
    }
    else {
        return sort keys %{$self->{skipStocks}};
    }
}

sub resetSkipStocks {
    my $self = shift;
    if (scalar(keys %{$self->{skipStocks}})) {
        $self->{skipStocks} = {};
        $self->stale(1);
    }
    return 1;
}

sub staleSets {
    my $self = shift;
    my $stale = 0;
    foreach my $hashKey (keys %{$self->{sets}}) {
        my $set = $self->getSet($hashKey);
        if ($set) {
            $stale += $set->stale();
        }
    }
    return $stale;
}

sub calculateMaxCashInvested {
    my ($self, $realizations) = @_;
    my @allTransactions = sort { $a->tm() <=> $b->tm() } map { @{$_->acquisitions()}, $_->divestment() } @$realizations;
    my $numberOfTrades = scalar(@allTransactions);
    @$realizations = ();
    my ($total, $max) = (0, 0);
    for (my $x=0; $x<scalar(@allTransactions); $x++) {
        my $transaction = $allTransactions[$x];
        $total += 0 - $transaction->cashEffect();
        $total > $max and $max = $total;
    }
    @allTransactions = ();
    if (wantarray()) {
        return $max, $numberOfTrades;
    }
    else {
        return $max;
    }
}

sub calculateStats {
    my $self = shift;
    my ($totalOutlays, $totalRevenues, $profit, $commissions, $regulatoryFees, $otherFees, $numberExcluded, $transactionCount) = (0, 0, 0, 0, 0, 0, 0, 0);
    my ($startDate, $endDate);
    my $setCount = 0;
    my @allRealizations = ();
    my $stats = $self->getNewStatsHash();
    $self->{stats} = $stats;
    $self->stale(0);
    foreach my $hashKey (keys %{$self->{sets}}) {
        my $set = $self->getSetFiltered($hashKey);
        if ($set) {
            if ($set->stale()) {
                $set->accountSales();
            }
            $numberExcluded += $set->unrealizedTransactionCount();
            next unless $set->success();

            ### Simple Totals
            $totalOutlays       += $set->totalOutlays();
            $totalRevenues      += $set->totalRevenues();
            $profit             += $set->profit();
            $commissions        += $set->commissions();
            $regulatoryFees     += $set->regulatoryFees();
            $otherFees          += $set->otherFees();
            $transactionCount   += $set->transactionCount();

            ### Date-Aware Totals
            push(@allRealizations, @{$set->realizations()});

            ### End-Date, Start-Date
            my $setStart = $set->startDate();
            $setStart or die "Didn't get set startDate for hashkey $hashKey\n";
            if (!defined($startDate)) {
                $startDate = $setStart;
            }
            elsif ($setStart < $startDate) {
                $startDate = $setStart;
            }
            my $setEnd   = $set->endDate();
            if (!$endDate) {
                $endDate = $setEnd;
            }
            elsif ($setEnd > $endDate) {
                $endDate = $setEnd;
            }
            $setCount++;
        }
        else {
            my $unfilteredSet = $self->getSet($hashKey);
            $numberExcluded += $unfilteredSet->unrealizedTransactionCount();
            if ($self->{skipStocks}{$hashKey}) {
                $numberExcluded += $unfilteredSet->transactionCount();
            }
        }
    }
    $stats->{numberExcluded} = $numberExcluded;
    if ($setCount > 0) {
        if ($totalOutlays) {
            my $profitOverOutlays = $profit / $totalOutlays;
            $stats->{totalOutlays}      = $totalOutlays;
            $stats->{totalRevenues}     = $totalRevenues;
            $stats->{profit}            = $profit;
            $stats->{commissions}       = $commissions;
            $stats->{regulatoryFees}    = $regulatoryFees;
            $stats->{otherFees}         = $otherFees;
            $stats->{profitOverOutlays} = $profitOverOutlays;
            $stats->{startDate}         = $startDate;
            $stats->{endDate}           = $endDate;
            my $secondsInYear = 60 * 60 * 24 * 365.25;
            my $secondsInAccount = $endDate->epoch() - $startDate->epoch();
            if (!$secondsInAccount) {
                croak "No time passed in account? Can't calculate time-related stats.";
            }
            my $annualRatio                     = $secondsInYear / $secondsInAccount;
            $stats->{annualRatio}               = $annualRatio;
            $stats->{profitOverYears}           = $profit * $annualRatio;
            my $maxCashInvested = $self->calculateMaxCashInvested(\@allRealizations);
            $stats->{maxCashInvested}           = $maxCashInvested;
            $stats->{profitOverOutlays}         = $profit / $totalOutlays;
            my $pomci                           = $profit / $maxCashInvested;
            $stats->{profitOverMaxCashInvested} = $pomci;
            $stats->{pomciOverYears}            = $pomci * $annualRatio;
            $stats->{numberOfTrades}            = $transactionCount;
            return 1;
        }
        else {
            carp "No totalOutlays found on which to compute stats.\n";
            return 0;
        }
    }
    else {
        carp "No realized gains in stock account.\n";
        return 0;
    }
}

sub getStats {
    my $self = shift;
    if ($self->{stats}{stale} or $self->staleSets()) {
        return $self->calculateStats();
    }
    else {
        return 1;
    }
}

sub stats {
    my $self = shift;
    $self->getStats();
    my $stats = $self->{stats};
    my @stats;
    for (my $x=0; $x<scalar(@$statsLinesArray); $x+=3) {
        my $key = $statsLinesArray->[$x+1];
        push(@stats, $key, $stats->{$key});
    }
    return \@stats;
}

sub statsString {
    my $self = shift;
    $self->getStats();
    my $stats = $self->{stats};
    my $statsString;
    for (my $x=0; $x<scalar(@$statsLinesArray); $x+=3) {
        my ($name, $key, $valPattern) = @$statsLinesArray[$x .. $x+2];
        $statsString .= sprintf("%30s $valPattern\n", $name, $stats->{$key});
    }
    return $statsString;
}

sub availableAcquisitionsString {
    my ($self, $inputKey) = @_;
    my ($string, @hashKeys);
    if ($inputKey) {
        @hashKeys = ($inputKey);
    }
    else {
        @hashKeys = keys %{$self->{sets}};
    }
    foreach my $hashKey (@hashKeys) {
        my $set = $self->getSet($hashKey);
        if ($set) {
            $string .= $set->availableAcquisitionsString();
        }
    }
    return $string;
}

sub statsForPeriod {
    my ($self, $tm1, $tm2) = @_;
    my ($totalOutlays, $totalRevenues, $profit, $commissions, $regulatoryFees, $otherFees, $transactionCount) = (0, 0, 0, 0, 0, 0, 0);
    my @allRealizations = ();
    my $setCount = 0;
    foreach my $hashKey (keys %{$self->{sets}}) {
        my $unfilteredSet = $self->getSet($hashKey);
        $unfilteredSet->setDateLimit($tm1, $tm2);
        my $set = $self->getSetFiltered($hashKey);
        if ($set) {
            $setCount++;
            $totalOutlays       += $set->totalOutlays();
            $totalRevenues      += $set->totalRevenues();
            $profit             += $set->profit();
            $commissions        += $set->commissions();
            $regulatoryFees     += $set->regulatoryFees();
            $otherFees          += $set->otherFees();
            $transactionCount   += $set->transactionCount();
            push(@allRealizations, @{$set->realizations()});
        }
        $unfilteredSet->clearDateLimit();
    }
    if ($setCount > 0 and $totalOutlays) {
        my $maxCashInvested = $self->calculateMaxCashInvested(\@allRealizations);
        return {
            totalOutlays                => $totalOutlays,
            totalRevenues               => $totalRevenues,
            maxCashInvested             => $maxCashInvested,
            profit                      => $profit,
            profitOverOutlays           => $profit / $totalOutlays,
            profitOverMaxCashInvested   => $profit / $maxCashInvested,
            commissions                 => $commissions,
            regulatoryFees              => $regulatoryFees,
            otherFees                   => $otherFees,
            numberOfTrades              => $transactionCount,
        };
    }
    else {
        carp "I couldn't calculate stats for the period from $tm1 to $tm2 for this stock account.\n";
        return undef;
    }
}

sub calculateAnnualStats {
    my $self = shift;
    $self->getStats();
    my $stats       = $self->{stats};
    my $startDate   = $stats->{startDate};
    my $endDate     = $stats->{endDate};
    my $offset      = $startDate->offset();
    my $annualStats = [];
    foreach my $year ($startDate->year() .. $endDate->year()) {
        my $yearStart = Time::Moment->new(
            year       => $year,
            month      => 1,
            day        => 1,
            hour       => 0,
            minute     => 0,
            second     => 01,
            nanosecond => 0,
            offset     => $offset,
        );
        my $yearEnd   = Time::Moment->new(
            year       => $year,
            month      => 12,
            day        => 31,
            hour       => 23,
            minute     => 59,
            second     => 59,
            nanosecond => 0,
            offset     => $offset,
        );
        my $yearStats = $self->statsForPeriod($yearStart, $yearEnd);
        $yearStats->{year} = $year;
        push(@$annualStats, $yearStats);
    }
    $stats->{annualStats} = $annualStats;
    $stats->{annualStatsStale} = 0;
    return $annualStats;
}

sub calculateQuarterlyStats {
    my $self = shift;
    $self->getStats();
    my $quarterlyStats = [];
    my $stats       = $self->{stats};
    my $startDate   = $stats->{startDate};
    my $endDate     = $stats->{endDate};
    my $offset      = $startDate->offset();
    my $startYear   = $startDate->year();
    my $startQuarter  = ceil($startDate->month()/3);
    my $currDate = Time::Moment->new(
        year       => $startYear,
        month      => ($startQuarter - 1) * 3 + 1,
        day        => 1,
        hour       => 0,
        minute     => 0,
        second     => 01,
        nanosecond => 0,
        offset     => $offset,
    );
    while ($currDate < $endDate) {
        my $quarterEnd   = $currDate->plus_months(3);
        my $quarterStats = $self->statsForPeriod($currDate, $quarterEnd);
        $quarterStats->{year}    = $currDate->year();
        $quarterStats->{quarter} = ceil($currDate->month()/3);
        push(@$quarterlyStats, $quarterStats);
        $currDate = $quarterEnd;
    }
    $stats->{quarterlyStats} = $quarterlyStats;
    $stats->{quarterlyStatsStale} = 0;
    return $quarterlyStats;
}

sub calculateMonthlyStats {
    my $self = shift;
    $self->getStats();
    my $monthlyStats = [];
    my $stats       = $self->{stats};
    my $startDate   = $stats->{startDate};
    my $endDate     = $stats->{endDate};
    my $offset      = $startDate->offset();
    my $startYear   = $startDate->year();
    my $startMonth  = $startDate->month();
    my $currDate = Time::Moment->new(
        year       => $startYear,
        month      => $startMonth,
        day        => 1,
        hour       => 0,
        minute     => 0,
        second     => 01,
        nanosecond => 0,
        offset     => $offset,
    );
    while ($currDate < $endDate) {
        my $monthEnd   = $currDate->plus_months(1);
        my $monthStats = $self->statsForPeriod($currDate, $monthEnd);
        $monthStats->{year}    = $currDate->year();
        $monthStats->{month} = $currDate->month();
        push(@$monthlyStats, $monthStats);
        $currDate = $monthEnd;
    }
    $stats->{monthlyStats} = $monthlyStats;
    $stats->{monthlyStatsStale} = 0;
    return $monthlyStats;
}

sub annualStats {
    my $self = shift;
    my $stats = $self->{stats};
    if ($stats->{annualStatsStale}) {
        return $self->calculateAnnualStats();
    }
    else {
        return $stats->{annualStats};
    }
}

sub quarterlyStats {
    my $self = shift;
    my $stats = $self->{stats};
    if ($stats->{quarterlyStatsStale}) {
        return $self->calculateQuarterlyStats();
    }
    else {
        return $stats->{quarterlyStats};
    }
}

sub monthlyStats {
    my $self = shift;
    my $stats = $self->{stats};
    if ($stats->{monthlyStatsStale}) {
        return $self->calculateMonthlyStats();
    }
    else {
        return $stats->{monthlyStats};
    }
}

sub periodicStatsString {
    my ($self, $params) = @_;
    my $periodHeadings          = $params->{periodHeadings};
    my $periodHeadingsPattern   = $params->{periodHeadingsPattern};
    my $periodKeys              = $params->{periodKeys};
    my $periodValuesPattern     = $params->{periodValuesPattern};
    my $periodHeadingsWidth     = $params->{periodHeadingsWidth};
    my $statsArray              = $params->{statsArray};
    my $statsString = sprintf("$periodHeadingsPattern $statsKeyHeadingsPattern\n", @$periodHeadings, @$statsKeyHeadings);
    my $lineLength = length($statsString);
    my $pattern = "$periodValuesPattern $statsKeysPattern\n";
    my $totals;
    my $verbose = $self->{verbose};
    if ($verbose) {
        $totals = [map { 0 } (0 .. scalar(@$statsKeys) - 1)];
    }
    foreach my $period (@$statsArray) {
        my @row = map { $period->{$_} } @$periodKeys;
        for (my $x=0; $x<scalar(@$statsKeys); $x++) {
            my $key = $statsKeys->[$x];
            my $value = $period->{$key};
            if ($verbose) {
                $totals->[$x] += $value;
            }
            push(@row, $value);
        }
        $statsString .= sprintf($pattern, @row);
    }
    if ($verbose) {
        $statsString .= '-'x$lineLength . "\n"
            . sprintf("%-${periodHeadingsWidth}s $statsKeysPattern\n", 'COL SUMS', @$totals);
    }
    $statsString .= '-'x$lineLength . "\n"
        . sprintf("%-${periodHeadingsWidth}s $statsKeysPattern\n", 'ACCT TOTAL', map { $self->{stats}{$_} } @$statsKeys);
    return $statsString;
}

sub annualStatsString {
    my $self = shift;
    return $self->periodicStatsString({
        periodHeadings          => [qw(Year)],
        periodHeadingsPattern   => "%10s",
        periodKeys              => [qw(year)],
        periodValuesPattern     => "%10d",
        periodHeadingsWidth     => 10,
        statsArray              => $self->annualStats(),
    });
}

sub quarterlyStatsString {
    my $self = shift;
    return $self->periodicStatsString({
        periodHeadings          => [qw(Year Quarter)],
        periodHeadingsPattern   => "%4s %7s",
        periodKeys              => [qw(year quarter)],
        periodValuesPattern     => "%4d %7d",
        periodHeadingsWidth     => 12,
        statsArray              => $self->quarterlyStats(),
    });
}

sub monthlyStatsString {
    my $self = shift;
    return $self->periodicStatsString({
        periodHeadings          => [qw(Year Month)],
        periodHeadingsPattern   => "%4s %5s",
        periodKeys              => [qw(year month)],
        periodValuesPattern     => "%4d %5d",
        periodHeadingsWidth     => 10,
        statsArray              => $self->monthlyStats(),
    });
}

sub profit {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{profit};
}

sub maxCashInvested {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{maxCashInvested};
}

sub profitOverOutlays {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{profitOverOutlays};
}

sub profitOverMaxCashInvested {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{profitOverMaxCashInvested};
}

sub profitOverYears {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{profitOverYears};
}

sub profitOverMaxCashInvestedOverYears {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{pomciOverYears};
}

sub commissions {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{commissions};
}

sub totalCommissions {
    return shift->commissions();
}

sub regulatoryFees {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{regulatoryFees};
}

sub otherFees {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{otherFees};
}

sub numberOfTrades {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{numberOfTrades};
}

sub numberExcluded {
    my $self = shift;
    $self->getStats();
    return $self->{stats}{numberExcluded};
}

sub totalFees {
    my $self = shift;
    return $self->regulatoryFees() + $self->otherFees();
}

sub summaryByStock {
    my $self = shift;
    my $spacer = Finance::StockAccount::Set->oneLinerSpacer();
    my $string = $spacer . Finance::StockAccount::Set->oneLinerHeader() . $spacer;
    my $sets = $self->getFilteredSets();
    foreach my $set (@$sets) {
        $string .= $set->oneLiner() . $spacer;
    }
    return $string;
}


sub realizationsString {
    my $self = shift;
    my $string = Finance::StockAccount::Realization->headerString();
    my $sets = $self->getFilteredSets();
    foreach my $set (@$sets) {
        $string .= $set->realizationsString();
    }
    return $string;
}


1;

__END__


=head1 NAME

Finance::StockAccount - Analyze past transactions in a personal stock account.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Analyze past transactions in a personal stock account.  Find out your total
profit, annual profit, quarterly profit, monthly profit, or profit for any
other arbitrary date/time range.  Discover what the most cash you had invested
in stocks at once was, over the course of your account from when it opened to
the present, or for any period.  Or get the total cash you spent on all stock
purchases, call that your totalOutlays and learn how the ratio of profit to
that totalOutlays changed from period to period.  Find out how much you spent
on commissions.  Match up the results with your experience by looking at profit
for each stock symbol separately.

    use Finance::StockAccount;

    # Object-oriented, so instantiate your object
    my $sa = Finance::StockAccount->new();

    # Now add your trades
    # One (fake/fantasy) trade a day for a week in January...
    $sa->stockTransaction({ # total outlay: 1000
        symbol          => 'AAA',
        dateString      => '20140106T150500Z', # This is a Time::Moment string, more on that below
        action          => 'buy',              # in the 'Required: date' section
        quantity        => 198,
        price           => 5,
        commission      => 10,
    });
    $sa->stockTransaction({ # total outlay: 1000
        symbol          => 'BBB',
        dateString      => '20140107T150500Z',
        action          => 'buy',
        quantity        => 99,
        price           => 10,
        commission      => 10,
    });
    $sa->stockTransaction({ # total revenue: 600
        symbol          => 'AAA',
        dateString      => '20140108T150500Z',
        action          => 'sell',
        quantity        => 100,
        price           => 6.10,
        commission      => 10,
    });
    $sa->stockTransaction({ # total revenue: 1070
        symbol          => 'BBB',
        dateString      => '20140109T150500Z',
        action          => 'sell',
        quantity        => 99,
        price           => 11,
        commission      => 19,
    });
    $sa->stockTransaction({ # total revenue: 670
        symbol          => 'AAA',
        dateString      => '20140110T150500Z',
        action          => 'sell',
        quantity        => 98,
        price           => 7,
        commission      => 16,
    });

    # How much did you make (or lose)?
    $sa->profit();                    # 340

    # What was the most cash you had invested in stocks at once?
    $sa->maxCashInvested();           # 2000

    # How much profit did you make as a share of the max you invested?
    $sa->profitOverMaxCashInvested(); # 0.17

    # Prefer just profit over outlays?  No problem.  It happens to be the same in this case.
    $sa->profitOverOutlays();         # 0.17

    # If you kept up that rate of profit over a year how much would you make?
    $sa->profitOverYears();           # 31046.25 (Wish I were that lucky.)

    # How much did you pay your broker?
    $sa->commissions();               # 65

    # How many transactions were counted in these statistics?
    $sa->numberOfTrades();            # 5

    # Get a list of statistics you can loop through
    my $stats = $sa->stats();

    # or get it broken down by date period
    $sa->annualStats();
    $sa->quarterlyStats();
    $sa->monthlyStats();

    # Want me to iterate through it and make it a string for you?
    print $sa->statsString();

    # Want that by date too?
    print $sa->annualStatsString();
    print $sa->quarterlyStatsString();
    print $sa->monthlyStatsString();

    # Get a simple one-stock-per-line breakdown of how you did
    print $sa->summaryByStock();

    # Need to exclude a couple stocks from analysis?
    $sa->skipStocks(qw(AAA BBB));

    # Include AAA and BBB again
    $sa->resetSkipStocks();

    # Curious how the module is doing its accounting?
    # Print the realizations (matches of acquisitions to divestment):
    print $sa->realizationsString();


My online brokerage account does not allow me to easily see how my stock
account is performing.  With a little research, I found this was common
practice with both online and offline brokerages, as well as financial
advisers.  So I wrote this software to find out my actual account performance,
and shared these modules so others could find out theirs.

This is a pure stock-transaction based set of modules.  Currently understood
transaction types include buy, sell, short, and cover.  This version (version
0.01) does not consider cash or dividends, but I would like to add those
features in future releases.  Because of that limitation, calculations cannot
be based purely on cash -- but rather on appreciation and depreciation of
stocks, and timing of transactions -- which gives an interesting (and I think
useful) perspective on account performance.

Looking at the "Analyze" tools in my OptionsXpress online brokerage account, I
saw it always used a "Last In, First Out" accounting method, which, frankly, is
ridiculous in terms of evaluating my stock trading performance.

So in these modules, accounting is done by what I call the Greatest Realized
Benefit (GRB) method: divestments (sales and covers) are processed from oldest
to newest, and one or more prior acquisitions (buys and shorts) are matched
with the sale by availability (meaning not all acquisition shares are already
tied to another divestment) and lowest cost of the acquisition.  Future
releases may add alternative accounting methods that could be selected by the
user, and I welcome your suggestions for those.

Along the way I tried to create a pure stock transaction class and a pure stock
class.  If you need such a thing, please look at

    Finance::StockAccount::Transaction
    Finance::StockAccount::Stock

which are included in the Finance::StockAccount installation.

If you happen to have an OptionsXpress online brokerage account you can import
the whole thing in one go with Finance::StockAccount::Import::OptionsXpress.  I
would like to add more formats, so, if you can, please donate an export from a
brokerage account to help this along.

Dates are stored as Time::Moment objects, and may be specified either as a
Time::Moment object (using the 'tm' property) or one of the string formats
natively understood by Time::Moment (using the 'dateString' property).

=head1 EXPLANATION

This set of modules is intended to give the lay investor (as opposed to the
high finance Wall Street type who already has a bunch of expensive tools
available to him) a meaningful sense of how his or her personal stock account
is doing.  It turns out a lot of both online and offline brokerages and
financial advisers and institutions obscure that information from their users
on the theory that if you knew how you were really doing, you would take your
money elsewhere, or bug them with questions and demands for improvement.  So to
get the information from them, you have to get the data, make a plan, and do
some accounting and some math.  It's one more thing on the to-do list so many
people don't get to it with any frequency.

With these modules you can get a better understanding of the performance of
your personal stock account.  Here's what you do: Create a new stock account
object, add your past stock transactions to it, and get statistics and
information from it.  You can set arbitrary date limits, to constrain that
information to a certain period, or use built in methods for yearly, quarterly,
or monthly data.

This set of modules deals purely in stock transactions.  There is no concept of
cash transactions.  Currently there is not even a concept of dividends, though
I intend to add that in a future release.  So far it is purely concerned with
acquisitions and divestments: their timing, absolute value, and relative value.

=head2 Terminology

=head4 Acquisition

A stock transaction of the type 'buy' or 'short'.  This is where the consumer
(or user) spends cash to gain an interest in some number of shares of a stock,
buying it if she expects it to go up, shorting it if she expects it to go down.

An acquisition, or part of an acquisition, becomes the cost basis for a later
divestment.

=head4 Divestment

A stock transaction of the type 'sell' or 'cover'.  This is where the consumer
sells her interest in a stock in return for cash, terminating the interest
gained in an earlier acquisition for some number of shares and gaining cash as
a result.

=head4 Realization

These modules attempt to match each divestment against one or more prior
acquisition(s), and use that match to calculate profit and other statistics
useful for evaluating stock account performance.  A successful match between a
divestment and one or more acquisitions is called a "realization" because it
represents the consummation or realization of the totalOutlays.

=head4 Set

The collection of all realizations for a particular stock.

=head4 Outlay

How much cash was spent on an acquisition transaction, including commissions
and fees.

=head4 Revenue

How much cash was received in a divestment, after commissions and fees have been subtracted.


=head2 Statistics, or "Why does that number look wrong?"

Unmatched transactions are not included in statistics: an acquisition that
cannot be paired with a divestment, or a divestment that cannot be paired with
an acquisition, is simply left out or ignored.  Here's an example to illustrate
why this is necessary: Suppose you bought $5,000 worth of stock 'FOO', but you
haven't sold it yet.  There is no way to evaluate whether that was a profitable
choice or not.  It could end up making you a millionaire, or its value could
drop to $0.

So when you see some statistics that look different from what you expected, one
of the things you might consider is whether any transactions were left out of
the analysis.  You can check that with the numberOfTrades and numberExcluded
methods (see below).  If you want more granular information, you might consider
diving down to the Finance::StockAccount::Set level, which provides more tools
for looking at the accounting of all trades in a specific stock.

Another area that might appear off at first inspection is the periodic stats.
This module handles date range limitations by figuring out what portion of a
given realization to attribute to the date range.  Imagine, for example, you
purchase a stock at d1 and sell it at d2.  Then you set a date range limit
starting at s1 and ending at s2 on this time line:

        s1                                                   s2
    |---|----------------------------------------------------|---|
    d1                                                           d2

Trades on d1 and d2 are outside the date range limit set by s1 and s2.  So a
simple evaluation would attribute no value to that realization within this time
line.  But the reality is that most of the value of that realization likely
accrued during this time.  It's also a simplification, since I don't look up
the stock price for that stock every day during that time, but this module
assumes a linear change in value and attributes to date range s1 to s2 a value
for this realization in proportion to the time it overlaps with the range d1 to
d2.  So $sa->profit() with this date range limit would return the profit for
the entire realization times (s2-s1)/(d2-d1).  Commissions, outlays, revenues,
etc., are all divided up the same way.

Perhaps the most practical application for this rule is the periodic look at
your stock performance.  So when you look at annualStats, quarterlyStats, or
monthlyStats, you will see what I would consider more accurate divisions of
value.  And a month where you did no trades would not necessarily mean a month
with no stats, as acquisitions would likely be gaining or losing value.

This can have the odd-looking side effect, however, of showing you a number of
trades considered in the statistics gathering that is larger than the number of
trades actually made within that date range.  And it means the purported
"number of trades" for each period adds up to more than the total number of
trades in the account.  I may try to remove this side effect in a future
version, so let me know if you find it too problematic or confusing...

=head1 METHODS


=head2 new


Constructor, instantiates and returns a new Finance::StockAccount object.
Typically called with no arguments:

    my $sa = Finance::StockAccount->new();

Currently there is only one StockAccount option/setting, which may be passed to
new if desired.  By default, attempts to add a stock transaction with a zero
price to a StockAccount object will be treated as suspect and fail.  I realize
that is personal preference, so it may optionally be overcome by setting
allowZeroPrice, like so:

    my $sa = Finance::StockAccount->new({allowZeroPrice => 1});

This option can also be set via method (see allowZeroPrice method below).


=head2 stockTransaction


This is the intended means of adding transactions to a StockAccount object.  An
instantiation hash is passed in.  Here is an example, me buying fifty shares of
stock in Twitter:

    $sa->stockTransaction({
        symbol          => 'TWTR',
        dateString      => '20140708T185304Z',
        action          => 'buy',
        quantity        => 50,
        price           => 37.33,
        commission      => 8.95,
    });

Several pieces of information are required.

B<Required: stock>

For one, there must be a stock.  It may be specified as a symbol string, as
above.  An optional exchange string may be passed in as well:

        symbol          => 'TWTR',
        exchange        => 'NYSE', # optional

Alternatively, a stock object can be created using Finance::StockAccount::Stock
and passed in with the stock key:

    use Finance::StockAccount;

    my $stock = Finance::StockAccount::Stock->new({
        symbol          => 'TWTR',
        exchange        => 'NYSE', # optional
    });
    $sa->stockTransaction({
        stock           => $stock,
        ...
    });

The same $stock object could then be used over and over to pass in transactions
on that stock. But even if you use a symbol string each time, they will be
treated as the same stock.  An exchange modifies a stock, so you could have two
stocks with the same symbol traded on two different exchanges and they would be
kept separate in StockAccount accounting. 

B<Required: date>

Second, there must be a date for the transaction.  Dates are necessary for
matching a sale to its prior purchase, or for calculating the mean annual
profit (or loss), for example.  Finance::StockAccount uses the CPAN module
Time::Moment to handle dates.  A date can either be passed in as a string using
the dateString key:

        dateString      => '20140708T185304Z',

or a Time::Moment object can be passed in using the tm key:

    my $tm = Time::Moment->new({ # the same date as the string above
        year        => 2014,
        month       => 7,
        day         => 8,
        hour        => 18,
        minute      => 53,
        second      => 4,
        offset      => 0,
    });
    $sa->stockTransaction({
        symbol          => 'TWTR',
        tm              => $tm,
        ...
    });

If using a string passed in with the dateString key, any string acceptable to
the Time::Moment->from_string method without using the 'lenient' flag will
work.  Please see the perldoc for Time::Moment for more information.

I chose to use Time::Moment over other Perl time modules because of its
efficiency in benchmark tests and its ease of use.  It seemed to do everything
I needed, to do it correctly, and to do it faster than any of the alternatives.
Please give it a chance, but also please do let me know if you run into any
problems using it in the context of this module.

B<Required: action>

A value for the 'action' key is required and must be one of the following
strings: 'buy', 'sell', 'short', or 'cover'.  E.g.:

    $sa->stockTransaction({
        ...
        action  => 'sell',
        ...
    });

B<Required: quantity>

A numeric value for quantity greater than zero is required:

    $sa->stockTransaction({
        ...
        quantity    => 60,
        ...
    });

B<Required: price>

A numeric value for price is also required:

    $sa->stockTransaction({
        ...
        price    => 4.55,
        ...
    });

By default, the price is required to be greater than zero, but see the
'allowZeroPrice' section below.

Additional information is not required, but can optionally be set when adding a
stock transaction:

B<Optional: commission>

    $sa->stockTransaction({
        ...
        commission      => 8.95,
        ...
    });

B<Optional: regulatoryFees>

In the United States the Securities and Exchange Commission imposes regulatory
fees on stock brokers or dealers.  Instead of paying these with their profits,
these for-profit companies often pass these fees on to their customers
directly.  The C<regulatoryFees> property could be used for similar purposes in
other jurisdictions.

See http://www.sec.gov/answers/sec31.htm for more information.

    $sa->stockTransaction({
        ...
        regulatoryFees  => 0.04,
        ...
    });

B<Optional: otherFees>

Any other fees that your jurisdiction, exchange, or broker adds in addition to
commission and regulatory fees.

    $sa->stockTransaction({
        ...
        otherFees       => 8.95,
        ...
    });


=head2 profit

Returns the numeric total profit (or loss) for all realizations in the stock account.

    my $profit = $sa->profit();

=head2 commissions

Returns the numeric total commissions paid on all included transactions.

    my $commissions = $sa->commissions();

=head2 totalCommissions

Same as commissions above.

=head2 maxCashInvested

Returns the maximum cash value invested in stocks at once.  Uses transaction
dates and outlays to find this value.

    my $maxCashInvested = $sa->maxCashInvested();

=head2 profitOverOutlays

    my $profitOverOutlays = $sa->profitOverOutlays();

Returns the ratio of profit to outlays.  In other words, the profit divided by
the outlays.

=head2 profitOverYears

    my $profitOverYears = $sa->profitOverYears();

Returns the ratio of profit to years.  So if you took the seconds between the
first transaction date and the last transaction date, and divided by the number
of seconds in a year to get time t, this returns profit divided by time t.

=head2 regulatoryFees

    my $regulatoryFees = $sa->regulatoryFees();

Returns the total of all regulatory fees paid in all transactions.

=head2 otherFees

    my $otherFees = $sa->otherFees();

Returns the total of all other fees paid in all transactions.

=head2 summaryByStock

Returns a string showing how you did for each stock.  It begins with a header,
and then a line for each stock with the following information:

    Symbol ROI Outlays Revenues Profit

with a row of dashes between each line as a visual cue for which values belong
together.

    print $sa->summaryByStock();

=head2 stats

Returns a reference to an array of statistics.  Every other position, starting
with zero, contains the name of the value stored at the next position.  Here is
each name prefixed by its location index:

     0  startDate
     2  endDate
     4  maxCashInvested
     6  totalOutlays
     8  totalRevenues
    10  profit
    12  profitOverYears
    14  profitOverOutlays
    16  profitOverMaxCashInvested
    18  pomciOverYears
    20  commissions
    22  regulatoryFees
    24  otherFees
    26  numberOfTrades
    28  numberExcluded

where "pomci" is short for "Profit Over Max Cash Invested".  As shown above,
there is an $sa->profit() method. But if you wished to get the profit from
stats instead, you could.  Perl arrays are zero-indexed, and each of the above
names is followed by the value, so to get the profit name and value:

    my $stats = $sa->stats();
    my $profitIndex = 10;
    my $profitName = $stats->[$profitIndex];
    my $profitValue = $stats->[$profitIndex+1];

Of course all that seems like a lot of work compared to calling $sa->profit().
But if for some reason you want to grab all the stats in one go in a reference
and process them somehow, stats is the method for you.

If you are doing much of this work, I suggest looking at the code I've
implemented in StockAccount.pm for methods stats() and statsString(), which
might provide you with some useful guides for how to more conveniently access
and traverse such information.  For example:

    for (my $x=0; $x<scalar(@$statsLinesArray); $x+=3) {
        my ($name, $key, $valPattern) = @$statsLinesArray[$x .. $x+2];
        $statsString .= sprintf("%30s $valPattern\n", $name, $stats->{$key});
    }

You have access to the $statsLinesArray structure through the method of the same name:

    my $statsLinesArray = $sa->statsLinesArray();

In version 0.01, it looked something like this:

    my $statsLinesArray = [
        'First Trade Date'                  => 'startDate'                  => '%35s',
        'Last Trade Date'                   => 'endDate'                    => '%35s',
        'Maximum Cash Invested at Once'     => 'maxCashInvested'            => '%35.2f',
        'Sum Outlays'                       => 'totalOutlays'               => '%35.2f',
        'Sum Revenues'                      => 'totalRevenues'              => '%35.2f',
        'Total Profit'                      => 'profit'                     => '%35.2f',
        'Profit Over Years'                 => 'profitOverYears'            => '%35.2f',
        'Profit Over Sum Outlays'           => 'profitOverOutlays'          => '%35.2f',
        'Profit Over Max Cash Invested'     => 'profitOverMaxCashInvested'  => '%35.2f',
        'The Above (^) Over Years'          => 'pomciOverYears'             => '%35.2f',
        'Total Commissions'                 => 'commissions'                => '%35.2f',
        'Total Regulatory Fees'             => 'regulatoryFees'             => '%35.2f',
        'Total Other Fees'                  => 'otherFees'                  => '%35.2f',
        'Num Trades Included in Stats'      => 'numberOfTrades'             => '%35d',
        'Num Trades Excluded from Stats'    => 'numberExcluded'             => '%35d',
    ];

I imagine this
structure may change in future versions.

=head2 statsString

Many users will likely just want to print out the stats for display instead of
looping through the values.  This method loops through them all and creates
readable formatted text you can print.

    print $sa->statsString();

Note that it's only formatted up to a point.   I did not add a currency
notation or do much formatting on the numbers.  This is partly because I don't
know what currency you're using, and partly because there are good modules
already written to format currency and numbers.  It is a job best left to
modules designed specifically for those purposes, such as Number::Format, and I
suggest you grab values using other Finance::StockAccount methods and use such
modules if you need good currency symbol and number formatting.

=head2 statsForPeriod

This method returns a reference to a hash of account statistics for an
arbitrary date range you provide.  The return value takes the following form:

    {
        totalOutlays                => $totalOutlays,
        totalRevenues               => $totalRevenues,
        maxCashInvested             => $maxCashInvested,
        profit                      => $profit,
        profitOverOutlays           => $profit / $totalOutlays,
        profitOverMaxCashInvested   => $profit / $maxCashInvested,
        commissions                 => $commissions,
        regulatoryFees              => $regulatoryFees,
        otherFees                   => $otherFees,
        numberOfTrades              => $transactionCount,
    }

The date range must be provided as two Time::Moment objects:

    my $statsForPeriod = $sa->statsForPeriod($tm1, $tm2);

where $tm2 should represent a time that came after $tm1.  Time::Moment provides
several methods instantiating new objects with date/time information.  When
doing so by hand, I find the most convenient one is usually the
Time::Moment->from_string method:

    # Create a new Time::Moment object for 2:00 PM, January 31, 2014 GMT
    my $tm1 = Time::Moment->from_string("20140131T140000Z")

Please see Time::Moment's documentation for more information.

=head2 annualStats

This method basically returns a reference to an array of "statsForPeriod" hashes above, one for each year in chronological order.

=head2 annualStatsString

Iterates through annualStats and returns a string of information in columns and
rows.  It looks something like this:

          Year      Outlays     Revenues  MaxInvested       Profit OverOut OverInvested   Commiss RegFees OthFees NumTrades
          2012     14454.48     15219.04     15989.18       764.56    0.05         0.05    229.99    0.37    0.00        80
          2013     59995.61     65866.67     16421.24      5871.07    0.10         0.36    508.56    1.27    0.00       116
          2014     28838.24     32162.69     12364.62      3324.46    0.12         0.27    237.51    0.75    0.00        73
    ------------------------------------------------------------------------------------------------------------------------
    COL SUMS      103288.33    113248.41     44775.05      9960.08    0.27         0.67    976.05    2.38    0.00       269
    ------------------------------------------------------------------------------------------------------------------------
    ACCT TOTAL    103288.34    113248.42     15989.18      9960.08    0.10         0.62    976.05    2.38    0.00       130


The columns explained further:

- Outlays - acquisition costs, including commissions and fees

- Revenues - divestment gains, reduced by commissions and fees

- Maximum Cash Invested - total acquisition cost at the moment of maximum
simultaneous unrealized investment. Put another way: the most cash you had
invested in stocks at once.

- Total Profit - revenues less outlays

- Profit Over Outlays - profit divided by outlays

- Profit Over Max Cash Invested - profit divided by max cash invested

- Total Commissions

- Total Regulatory Fees

- Total Other Fees

- Num Trades - number of trades examined that contributed to these stats values

In COL SUMS row, the columns are summed (even for columns where that doesn't
make much sense), and then in the ACCT TOTAL row, total account statistics are
presented.

Notice how "off" the NumTrades values look when summed compared to the account
total.  This is because it counts the trades in all realizations that overlap
the time period, so many trades are counted twice.  See "Why does that number
look wrong?" above.

=head2 quarterlyStats

Like annualStats but per quarter.  Here a quarter is defined by dividing up
the year into four three-month periods, starting in January and ending in
December.

=head2 quarterlyStatsString

Like annualStatsString but for quarter.

=head2 monthlyStats

Like annualStats but per month.

=head2 monthlyStatsString

Like annualStatsString but per month.

=head2 getSet

    my $set = $sa->getSet($hashKey);

Returns the Finance::StockAccount::Set object specified by $hashKey, or undef
if not found.

If you want to get into the details of the accounting for a particular set,
accessing the set is the way to go.  You can retrieve the set using a hashKey
made up of the stock symbol and exchange in the form:

    symbol:exchange

So for example, if I added stock transactions for Apple stock using the symbol
AAPL and the exchange NASDAQ, my hashKey would be

    AAPL:NASDAQ

The set can be returned with the getSet method passing in the hashKey as a
string:

    my $appleSet = $sa->getSet('AAPL:NASDAQ');

If you didn't set an exchange, which is optional for stock objects, just use
the symbol:

    my $appleSet = $sa->getSet('AAPL');

That will give you a Finance::StockAccount::Set object.
Finance::StockAccount::Set is installed with the Finance::StockAccount module.
To learn more about sets, run

    perldoc Finance::StockAccount::Set

from the command line.

=head2 getSetFiltered

    my $set = $sa->getSetFiltered($hashKey);

Same as getSet except it filters out all sets that are ruled out by skipStocks
(see skipStocks method below) or for which there are no realizations -- no pairings of
acquisition and divestment.  Returns undef if no set is found matching the
hashKey, containing realizations, and not on the skipStocks list.

=head2 getFilteredSets

    my $sets = $sa->getFilteredSets();

Returns a reference to the array of all sets in the account that match the
getSetFiltered criteria above.

=head2 realizationsString

    print $sa->realizationsString();

If you want to get even further down into the weeds than
Finance::StockAccount::Set objects, you can look at
Finance::StockAccount::Realization objects.  Sets are made up of them, so you
can access them through the Set object.  But for a quick overview/printout, you
can use this method to retrieve a string showing each realization.  The method
loops through each set, and each realization within the set, retrieving a
string for each one that is combined into the return value.

=head2 availableAcquisitionsString

    print $sa->availableAcquisitionsString('WFM');

Returns the string showing all acquisitions not yet paired with a divestment,
which one could use to evaluate cost basis for a potential sale or cover.  With
$hashKey passed in, it will be limited to the Set object matching $hashKey (a
string in the form '<symbol>:<exchange>', e.g. 'TWTR:NYSE', or just '<symbol>',
e.g. 'TWTR', if no exchange was specified on the stock).

With no arguments, loops through all sets and aggregates the data into one
string.

=head2 skipStocks

After adding a bunch of transactions, or importing an entire account history,
you may wish to exclude certain stocks from calculations, at least temporarily.
You can do this using the skipStocks method.  Pass it a string list of the
stock symbols you would like to skip.  If the optional exchange parameter was
set, you must join the exchange string to the symbol string with a colon.
For example:

    $sa->skipStocks(qw(AMD TWTR:NYSE));
    my $profit = $sa->profit();
    ...

Now any calculations, such as profit, will exclude the stock specified as
symbol => 'AMD' with no exchange, and the stock specified as symbol => 'TWTR',
exchange => 'NYSE'.

New calls to the method are additive, so you can add skip stocks one at a time
or all at once or anywhere in between.

If you'd like to see the current set of skipStocks, you can call the method
with no arguments and it will return an alphabetically sorted list of strings:

    print join(', ', $sa->skipStocks()), "\n"; # prints "AMD, TWTR:NYSE\n"

If there are no skip stocks to return, it will return undef.

=head2 resetSkipStocks

Use this method to reset the skipStocks list to an empty list.

=head2 allowZeroPrice

Transactions where the price is zero are treated as suspect by default, and
stockTransaction will not add them to the StockAccount object.  However, there
are some legitimate use cases where one might want them to be included, so you
can set the allowZeroPrice option on the StockAccount object to do that:

    $sa->allowZeroPrice(1); # allow transactions with price == 0
    $sa->allowZeroPrice(0); # disallow transactions with price == 0

or check the value with the same method and no arguments:

    if ($sa->allowZeroPrice()) {
        ... do something ...
    }

As mentioned above, it can also be set using the new method, described above.

=head1 INSTALLATION

A classic and still great means of installing a Perl module is basically as
follows.  Download the tarball, extract it somewhere, and then in that
directory run these commands:

    perl Makefile.PL
    make
    make test
    make install

Of course there are lots of options and alternatives.  For example, say you
were on unix or linux and you created a "plib" directory in your home directory
and configured Perl to look there, and you wanted to install there instead.
You could change that first line to do that:

    perl Makefile.PL INSTALL_BASE=~/plib

And there are lots of other things you can do.  I recommend looking at

    perldoc ExtUtils::MakeMaker

(or just view it on cpan or metacpan) for more information.

Also, there are several tools for installing Perl modules, such as cpanm.  Many
of them will install dependencies for you.  I did not test my distribution with
all such tools, so please let me know if you have problems installing this
module with any of them.

This is by no means meant as an authoritative guide for how to install Perl
modules: there is a lot of good material on that subject online and in perldoc
pages, so please look for those sources.

=head1 MORE EXAMPLES

If you download this module as a tarball from cpan or metacpan and extract it
somewhere, you should see a

    t/

directory.  In there are tests written for this module, providing more examples
of code that makes use of this module.  Note that much of this code was written
specifically to test features and methods of this module, and may not represent
typical or ideal usage.  Note that several of these tests require the files in

    t/data/

to work.

=head1 AUTHOR

John Everett Refior, C<< <jrefior at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-stockaccount at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-StockAccount>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::StockAccount

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-StockAccount>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-StockAccount>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-StockAccount>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-StockAccount/>

=back

=head1 ACKNOWLEDGEMENTS

I would like to thank the Perl Monks for contributing their wisdom when I
posted questions about how to handle date/time and whether there was already a
module capable of doing what I planned.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 John Everett Refior.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
