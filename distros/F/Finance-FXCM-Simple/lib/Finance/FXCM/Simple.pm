use strict;
use warnings;
package Finance::FXCM::Simple;
$Finance::FXCM::Simple::VERSION = '0.014';
require XSLoader;
XSLoader::load(
    'Finance::FXCM::Simple',
    $Finance::FXCM::Simple::{VERSION} ? ${ $Finance::FXCM::Simple::{VERSION} } : ()
);

use YAML::XS;

sub getTrades {
    my ($self) = @_;
    my $trades = Load($self->getTradesAsYAML());
    return defined($trades) ? $trades : [];
}

sub getTradesForSymbol {
    my ($self, $symbol) = @_;

    return [ grep { $_->{symbol} eq $symbol } @{ $self->getTrades() } ];
}

sub getOffersHash {
    my ($self) = @_;
    my $offersHash = Load($self->getOffersHashAsYAML());
    return $offersHash;
}

1;

=encoding utf8

=head1 NAME

Finance::FXCM::Simple - A synchronous wrapper to the FXCM ForexConnect API which is simple to use.

=head1 SYNOPSIS

        my $ff = Finance::FXCM::Simple->new(
                        $ENV{FXCM_USER},
                        $ENV{FXCM_PASSWORD},
                        "Demo",
                        "http://www.fxcorporate.com/Hosts.jsp");

        # Don't receive data updates to EUR/CAD
        $ff->setSubscriptionStatus('EUR/CAD', 'D');

        # Receive data updates to EUR/USD
        $ff->setSubscriptionStatus('EUR/USD', 'T');

        # Hash of data subscription status keyed on instrument
        my $offers_hash = $ff->getOffersHash();

        # Get current ask price for instrument
        $ff->getAsk("EUR/USD");

        # Get current bid price for instrument
        $ff->getBid("EUR/USD");

        # Get current account balance
        $ff->getBalance();

        # The minimum size that can be traded in instrument
        $ff->getBaseUnitSize("XAU/USD");

        # Open long position in instrument at current market price
        $ff->openMarket("EUR/USD", "B", 10000);

        # Open short position in instrument at current market price
        $ff->openMarket("EUR/GBP", "S", 10000);

        # Get list of open positions
        my $trades = $ff->getTrades();
        foreach my $trade(@$trades) {
            # Close existing open position at current market price
            $ff->closeMarket($trade->{id}, $trade->{size});
        }

        # Fetch 100 bars of 5 minute historical data for instrument EUR/USD and save to /tmp/EURUSD
        $ff->saveHistoricalDataToFile("/tmp/EURUSD", "EUR/USD", "m5", 100);

=head1 DESCRIPTION

Simple wrapper to FXCM's ForexConnect API, allows you to open/close/query positions in both real or demo FXCM trading accounts, as well as download historical price data for instruments supported by FXCM.

=head1 COMPILING

This module depends on L<FXCM's ForexConnect library|http://fxcodebase.com/wiki/index.php/Download> which is available in binary form only.

By default, only a small subset of tests run. To run the full test suite, you can optionally create a L<FXCM demo account|https://www.fxcm.com/forex-trading-demo/>.


    curl http://fxcodebase.com/bin/forexconnect/1.3.2/ForexConnectAPI-1.3.2-Linux-x86_64.tar.gz | tar zxf - -C ~
    sudo cp -R ~/ForexConnectAPI-1.3.2-Linux-x86_64/include/* /usr/include/.
    sudo cp -R ~/ForexConnectAPI-1.3.2-Linux-x86_64/lib/* /usr/lib64/.

    FXCONNECT_HOME=~/ForexConnectAPI-1.3.2-Linux-x86_64
    FXCM_USER=DEMO_USERNAME # Optional, only required to run full test suite
    FXCM_PASSWORD=DEMO_PWD  # Optional, only required to run full test suite
    perl Makefile.PL
    make
    make test
    sudo make install

=head2 METHODS

=over 12

=item C<new($username, $password, $type, $url)>

=over 16

=item C<$username>

Your FXCM account username

=item C<$password>

Your FXCM account password

=item C<$type>

The account type the login credentials apply to. Either 'Demo' or 'Real'.


=item C<$url>

The url to connect to, typically this will be 'http://www.fxcorporate.com/Hosts.jsp'

=back


=item C<getAsk($instrument)>

Get current ask price of instrument.  This is the price you can buy at.  Subscription status must be set, see L</"setSubscriptionStatus($instrument, $status)">

=over 16

=item C<$instrument>

The instrument to fetch ask price for.

=back

=item C<getBid($instrument)>

Get current bid price of instrument.  This is the price you can sell at.  Subscription status must be set, see L</"setSubscriptionStatus($instrument, $status)">

=over 16

=item C<$instrument>

The instrument to fetch bid price for.

=back

=item C<openMarket($instrument, $direction, amount)>

Opens a position at current market price.

=over 16

=item C<$instrument>

The instrument to open a market position in.

=item C<$direction>

Use 'B' for Buy (long) or 'S' for Sell (short).

=item C<$amount>

An integer representing the size of the position being opened. This must be a multiple of getBaseUnitSize 

=back

=item C<closeMarket($tradeID, $amount)>

Close an existing position at current market prices

=over 16

=item C<$tradeID>

Unique identifier representing a trade. This can be obtained by calling getTrades.

=item C<$amount>

An integer representing the size of the position to be closed. This can either be partial or the full position. Must be a multiple of getBaseUnitSize.

=back

=item C<getTrades()>

Returns a reference to a list of currently opened trades.  Each element in the list is a reference to an hash with the following keys:

=over 16

=item C<direction>

Either "long" or "short".

=item C<symbol>

=item C<openPrice>

=item C<openDate>

=item C<pl>

Current profit/loss of the position, expressed in the account base currency.

=item C<id>

Unique trade identifier. This is necessary to close the position with closeMarket.

=item C<size>

=back

=item C<getBalance()>

Current account balance, expressed in the account base currency.

=item C<getBaseUnitSize($instrument)>

Returns an integer representing the base position size for $instrument.
Positions opened in $instrument must have a size which is a multiple of this value.

=over 16

=item C<$instrument>

The instrument to fetch base unit size for.

=back

=item C<saveHistoricalDataToFile($filename, $instrument, $tf, $numberOfItems)>

Fetches historical data for instrument in a given timeframe and saves it to a file on disk.

=over 16

=item C<$filename>

Filename where to save data to.

=item C<$instrument>

Instrument for which to fetch data.

=item C<$tf>

Timeframe which to fetch data in. This can be one of:

=over 20

=item C<m1>

One minute

=item C<m5>

Five minutes

=item C<m15>

Fifteen minutes

=item C<m30>

Thirty minutes

=item C<H1>

Hourly

=item C<D1>

Daily

=item C<W1>

Weekly

=back

=item C<$numberOfItems>

An integer representing number of items of historical data to download.

=back

=item C<getOffersHash()>

Returns a reference to an hash where the key is an instrument code and the value is that code's current subscription status.
You can only call getBid and getAsk on currently subscribed instruments.

=item C<setSubscriptionStatus($instrument, $status)>

=over 16

=item C<$instrument>

Instrument to set subscription status for

=item C<$status>

Value indicating wether subscription should be set or unset. Use 'T' to subscribe, 'D' to ubsubscribe.

=back

=back

=head1 SOURCE CODE

L<https://github.com/joaocosta/Finance-FXCM-Simple>

=head1 CI

L<https://travis-ci.org/joaocosta/Finance-FXCM-Simple>

=head1 AUTHOR

João Costa <joaocosta@zonalivre.org>

=head1 COPYRIGHT AND LICENSE

 This software is Copyright (c) 2016 by João Costa.

 This is free software, licensed under:

   The MIT (X11) License

=head1 SEE ALSO

L<ForexConnect API documentation|http://www.fxcorporate.com/help/CPlusPlus/>

=cut
