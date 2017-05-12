#!/usr/bin/perl -wT
use Test::More tests => 30;

use 5.010;
use warnings;
use strict;
use lib qw(.);

use Finance::LocalBitcoins::API;
use Data::Dumper;

use constant DEBUG   => 0;
use constant VERBOSE => 0;

# Your LocalBitcoins API OAuth token goes here...
use constant OAUTH_TOKEN        => 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';

use constant PACKAGE             => 'Finance::LocalBitcoins::API';

# turn test groups On/Off Globally...
use constant RUN_PUBLIC_TESTS    => 1;
use constant RUN_PRIVATE_TESTS   => 1;

# Public Test Switches...
use constant TEST_TICKER         => 1;
use constant TEST_TRADEBOOK      => 1;
use constant TEST_ORDERBOOK      => 1;

# Private Test Switches...
# Legend:
#      1 = ON
#      0 = OFF
#  undef = Non-functional test.
#  (non-functional tests are ones that have not been tested and approved to work by the developers)
use constant TEST_BALANCE        => 1;
use constant TEST_WALLET         => 1;
use constant TEST_USER           => 1;
use constant TEST_ME             => 1;
use constant TEST_PIN            => 1;
use constant TEST_DASH           => 1;
use constant TEST_RELEASE_ESCROW => undef;
use constant TEST_PAID           => undef;
use constant TEST_MESSAGES       => undef;
use constant TEST_MESSAGE        => undef;
use constant TEST_DISPUTE        => undef;
use constant TEST_CANCEL         => undef;
use constant TEST_FUND           => undef;
use constant TEST_NEW_CONTACT    => undef;
use constant TEST_CONTACT        => undef;
use constant TEST_CONTACTS       => undef;
use constant TEST_SEND           => undef;
use constant TEST_SENDPIN        => undef;
use constant TEST_ADDRESS        => undef; # requires 'money' permission
use constant TEST_LOGOUT         => undef;
use constant TEST_ADS            => 1;
use constant TEST_AD_GET         => undef;
use constant TEST_ADS_GET        => undef;
use constant TEST_AD_UPDATE      => undef;
use constant TEST_AD             => undef;

# this is required for pin based tests...
# note: I dont think this will work. Not sure. I think Pin is time dependant... but I dont know. Tests will tell...
use constant TEST_CURRENCY        => 'USD'; # ie: USD, EUR, GBP, CAD, etc...
use constant PINCODE              => 'Your PINCODE here';
use constant EXTERNAL_BTC_ADDRESS => 'an external BTC wallet address that you own/control';

use constant PUBLIC_TESTS => [
    {
        name   => 'Ticker',
        method => 'ticker',
        active => TEST_TICKER,
    },
    {
        name   => 'Tradebook',
        method => 'tradebook',
        active => TEST_TRADEBOOK,
        params => {
            currency => TEST_CURRENCY,
        },
    },
    {
        name   => 'Orderbook',
        method => 'orderbook',
        active => TEST_ORDERBOOK,
        params => {
            currency => TEST_CURRENCY,
        },
    },
];

use constant PRIVATE_TESTS => [
    {
        name   => 'Balance',
        method => 'balance',
        active => TEST_BALANCE,
    },
    {
        name   => 'Wallet',
        method => 'wallet',
        active => TEST_WALLET,
    },
    {
        name   => 'User',
        method => 'user',
        active => TEST_USER,
        params => { username => 'bitcoinbaron' },
    },
    {
        name   => 'Me',
        method => 'me',
        active => TEST_ME,
    },
    {
        name   => 'Pin',
        method => 'pin',
        active => TEST_PIN,
        params => { pincode => PINCODE }
    },
    {
        name   => 'Dash',
        method => 'dash',
        active => TEST_DASH,
    },
    {
        name   => 'Release Escrow',
        method => 'release_escrow',
        active => TEST_RELEASE_ESCROW,
    },
    {
        name   => 'Paid',
        method => 'paid',
        active => TEST_PAID,
    },
    {
        name   => 'Messages',
        method => 'messages',
        active => TEST_MESSAGES,
    },
    {
        name   => 'Dispute',
        method => 'dispute',
        active => TEST_DISPUTE,
    },
    {
        name   => 'Cancel',
        method => 'cancel',
        active => TEST_CANCEL,
    },
    {
        name   => 'Fund',
        method => 'fund',
        active => TEST_FUND,
    },
    {
        name   => 'New Contact',
        method => 'new_contact',
        active => TEST_NEW_CONTACT,
    },
    {
        name   => 'Contact',
        method => 'contact',
        active => TEST_CONTACT,
    },
    {
        name   => 'Contacts',
        method => 'contacts',
        active => TEST_CONTACTS,
    },
    {
        name   => 'Send',
        method => 'send',
        active => TEST_SEND,
    },
    {
        name   => 'Sendpin',
        method => 'sendpin',
        active => TEST_SENDPIN,
    },
    {
        name   => 'Address',
        method => 'address',
        active => TEST_ADDRESS,
    },
    {
        name   => 'Logout',
        method => 'logout',
        active => TEST_LOGOUT,
    },
    {
        name   => 'Ads',
        method => 'ads',
        active => TEST_ADS,
    },
    {
        name   => 'Ad Get',
        method => 'ad_get',
        active => TEST_AD_GET,
    },
    {
        name   => 'Ads Get',
        method => 'ads_get',
        active => TEST_ADS_GET,
    },
    {
        name   => 'Ad Update',
        method => 'ad_update',
        active => TEST_AD_UPDATE,
    },
    {
        name   => 'Ad',
        method => 'ad',
        active => TEST_AD,
    },
];

main->new->go;
sub new { bless {} => shift }

sub go  {
    my $self = shift;

    can_ok(PACKAGE, qw(new));

    say '=== Begin PUBLIC tests' if VERBOSE;
    isa_ok($self->set_public, PACKAGE);
    foreach my $test (@{PUBLIC_TESTS()}) {
        SKIP: {
            my ($name, $method, $active, $params) = @{$test}{qw(name method active params)};
            skip "\$api->$method()\ttest turned OFF", 1 unless RUN_PUBLIC_TESTS and $active;
            unless ($self->$method($self->api->$method($params ? (%$params) : ()))) {
                diag(Data::Dumper->Dump([$self->api->error], [sprintf '%s Error', $name]));
            }
            ok($self->$method, sprintf 'public request: $api->%s()', $method);
            print Data::Dumper->Dump([$self->$method],[$name]) if DEBUG;
        }
    }
    say '=== End PUBLIC tests' if VERBOSE;

    say '=== Begin PRIVATE tests' if VERBOSE;
    isa_ok($self->set_private, PACKAGE);
    foreach my $test (@{PRIVATE_TESTS()}) {
        SKIP: {
            my ($name, $method, $active, $params) = @{$test}{qw(name method active params)};
            skip "\$api->$method()\ttest turned OFF", 1 unless RUN_PRIVATE_TESTS and $active;
            unless ($self->$method($self->api->$method($params ? (%$params) : ()))) {
                diag(Data::Dumper->Dump([$self->api->error], [sprintf '%s Error', $name]));
            }
            ok($self->$method, sprintf 'private request: $api->%s()', $method);
            print Data::Dumper->Dump([$self->$method],[$name]) if DEBUG;
        }
    }
    say '=== End PRIVATE tests' if VERBOSE;
}

sub set_public     { shift->api(Finance::LocalBitcoins::API->new) }
sub set_private    { shift->api(Finance::LocalBitcoins::API->new(token => OAUTH_TOKEN)) }

sub api            { get_set(@_) }
sub ticker         { get_set(@_) }
sub tradebook      { get_set(@_) }
sub orderbook      { get_set(@_) }
sub balance        { get_set(@_) }
sub wallet         { get_set(@_) }
sub user           { get_set(@_) }
sub me             { get_set(@_) }
sub pin            { get_set(@_) }
sub dash           { get_set(@_) }
sub release_escrow { get_set(@_) }
sub paid           { get_set(@_) }
sub messages       { get_set(@_) }
sub message        { get_set(@_) }
sub dispute        { get_set(@_) }
sub cancel         { get_set(@_) }
sub fund           { get_set(@_) }
sub new_contact    { get_set(@_) }
sub contact        { get_set(@_) }
sub contacts       { get_set(@_) }
sub send           { get_set(@_) }
sub sendpin        { get_set(@_) }
sub address        { get_set(@_) }
sub logout         { get_set(@_) }
sub ads            { get_set(@_) }
sub ad_get         { get_set(@_) }
sub ads_get        { get_set(@_) }
sub ad_update      { get_set(@_) }
sub ad             { get_set(@_) }

sub get_set {
   my $self = shift;
   my $attribute = ((caller(1))[3] =~ /::(\w+)$/)[0];
   $self->{$attribute} = shift if scalar @_;
   return $self->{$attribute};
}

1;

__END__


=cut

    say '=== Begin PUBLIC tests';
    $self->set_public;
    if (TEST_TICKER) {
        print '=== Ticker...';
        my $ticker = $self->api->ticker;
        if ($ticker) {
            say 'success';
            say Dumper $ticker if DEBUG;
            say "\n\tproof:";
            foreach my $currency (keys %$ticker) {
               printf "\t%s last traded at %s\n", $currency, $ticker->{$currency}->{last};
            }
            print "\n";
        }
        else {
            say 'failed';
            say Dumper $self->api->error if DEBUG;
        }
    }

    if (TEST_TRADEBOOK) {
        print '=== Tradebook...';
        my $tradebook = $self->api->tradebook(currencypair => TEST_CURRENCY_PAIR);
        if ($tradebook) {
            say 'success';
            say Dumper $tradebook if DEBUG;
            say "\n\tproof:";
            printf "\tI see %d trades\n", scalar @$tradebook;
            printf "\tI see one trade of %s %s for \$%s %s at a rate of \$%s %s/%s [unixtime: %s]\n", @{$tradebook->[0]}{qw(for_currency_amount for_currency trade_currency_amount trade_currency rate trade_currency for_currency date)};
            # I see a trade of 0.22 BTC for $116 CAD at a rate of $580/BTC [unixtime: 1401001012].
            print "\n";
        }
        else {
            say 'failed';
            say Dumper $self->api->error if DEBUG;
        }
    }

    if (TEST_ORDERBOOK) {
        print '=== Orderbook...';
        my $orderbook = $self->api->orderbook(currencypair => TEST_CURRENCY_PAIR);
        if ($orderbook) {
            say 'success';
            say Dumper $orderbook if DEBUG;
            say "\n\tproof:";
            printf "\tI see %s bids\n", scalar @{$orderbook->{bids}};
            my @sorted_bids = sort {$b->[0] <=> $a->[0]} @{$orderbook->{bids}};
            printf "\tThe best bid in the list is %11.8f BTC for %7.2f CAD/BTC\n", @{$sorted_bids[0]}[1,0];
            printf "\tThe next bid in the list is %11.8f BTC for %7.2f CAD/BTC\n", @{$sorted_bids[1]}[1,0] if scalar @sorted_bids > 1;
 
            printf "\tI see %s asks\n", scalar @{$orderbook->{asks}};
            my @sorted_asks = sort {$a->[0] <=> $b->[0]} @{$orderbook->{asks}};
            printf "\tThe best ask in the list is %11.8f BTC for %7.2f CAD/BTC\n", @{$sorted_asks[0]}[1,0];
            printf "\tThe next ask in the list is %11.8f BTC for %7.2f CAD/BTC\n", @{$sorted_asks[1]}[1,0] if scalar @sorted_asks > 1;
            print "\n";
        }
        else {
            say 'failed';
            say Dumper $self->api->error if DEBUG;
        }
    }
    say '=== Done PUBLIC tests';

    if (RUN_PRIVATE_TESTS) {
        say '=== Begin PRIVATE tests';
        $self->set_private;

        if (TEST_BALANCE) {
            say 'Balance...';
            my $balance = $self->api->balance();
            if ($balance) {
                say 'success';
                say Dumper $balance if DEBUG;
                foreach my $currency (keys %$balance) {
                    printf "You have %s %s in your wallet.\n", $currency, $balance->{$currency} if VERBOSE;
                }
            }
            else {
                say 'failed';
                say Dumper $self->api->error if DEBUG;
            }
        }

        if (TEST_TRANSACTIONS) {
            say 'Transactions...';
            my $transactions = $self->api->transactions(currencypair => 'BTCCAD');
            if ($transactions) {
                say 'success';
                say Dumper $transactions if DEBUG;
                foreach my $transaction (@$transactions) {
                    printf "Transaction [%s]: %s %s\n", @{$transaction}{qw(reason total currency)};
                }
            }
            else {
                say 'failed';
                say Dumper $self->api->error if DEBUG;
            }
        }

        if (TEST_TRADE_HISTORY) {
            say 'Trade History...';
            my $trade_history = $self->api->trade_history(currencypair => 'BTCCAD');
            if ($trade_history) {
                say 'success';
                say Dumper $trade_history if DEBUG;
                foreach my $trade (@$trade_history) {
                    #Bought 0.5 BTC @ 345.6 CAD/BTC for a total of 250.34 CAD
                    printf "Trade [%s, oid:%s]: bought %s %s @ %s %s/%s for a total of %s %s\n", @{$trade}{qw(id oid for_currency_amount for_currency rate trade_currency for_currency trade_currency_amount trade_currency)};
                }
            }
            else {
                say 'failed';
                say Dumper $self->api->error if DEBUG;
            }
        }

        if (TEST_ORDER_HISTORY) {
            say 'Order History...';
            my $order_history = $self->api->order_history(currencypair => 'BTCCAD');
            if ($order_history) {
                say 'success';
                say Dumper $order_history if DEBUG;
                foreach my $order (@$order_history) {
                    say 'Order: ' . join(' ', values @$order);
                }
            }
            else {
                say 'failed';
                say Dumper $self->api->error if DEBUG;
            }
        }

        if (TEST_ORDER) {
            say 'Order...';
            my $currencypair = 'BTCCAD';
            my $mode         = 'buy';
            my $amount       = '1.00001';
            my $price        = '0.01';
            my $order = $self->api->order(
                currencypair => $currencypair,
                mode         => $mode,
                amount       => $amount,
                price        => $price,
            );
            if ($order) {
                say 'success';
                say Dumper $order if DEBUG;
                printf "Placed Order. status: %s, id: %s, success: %s\n", @{$order}{qw(status id success)};
                if (TEST_ORDER_CANCEL) {
                    say 'Order Cancel...';
                    my $id = $order->{id};
                    my $order_cancel = $self->api->order_cancel(id => $id);
                    if ($order_cancel) {
                        say 'success';
                        say Dumper $order_cancel if DEBUG;
                        printf "Cancelled Order ID: %s\n", $order_cancel->{id};
                    }
                    else {
                        say 'failed';
                        say Dumper $self->api->error if DEBUG;
                    }
                }
            }
            else {
                say 'failed';
                say Dumper $self->api->error if DEBUG;
            }
        }

        if (TEST_WITHDRAW) {
            say 'Withdraw...';

            # are you kidding me??? you want to withdraw BTC on a test???
            die 'Are you nuts? You will have to change this code to test a withdrawal';

            my $amount   = '0.00000001';
            my $currency = 'BTC';

            my $withdraw = $self->api->withdraw(amount => $amount, currency => $currency, address => EXTERNAL_BITCOIN_ADDRESS);
            if ($withdraw) {
                say 'success';
                say Dumper $withdraw if DEBUG;
                printf "Withdrawal [%s]: %s %s %s %s to %s with a fee of %s %s\n", @{$withdraw}{qw(publictransactionid user reason amount currency wallet fee currency)};
            }
            else {
                say 'failed';
                say Dumper $self->api->error if DEBUG;
            }
        }
        say '=== Done PRIVATE tests';
    }
=cut

