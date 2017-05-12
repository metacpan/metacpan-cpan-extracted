#!/usr/bin/perl -wT
use Test::More tests => 11;

use 5.010;
use warnings;
use strict;
use lib qw(.);

use Finance::CaVirtex::API;
use Data::Dumper;

use constant DEBUG   => 0;
use constant VERBOSE => 0;

# Your CaVirtex API token and secret go here...
use constant API_TOKEN          => 'CaVirtex token  here';
use constant API_SECRET         => 'CaVirtex secret here';

use constant PACKAGE            => 'Finance::CaVirtex::API';

use constant TEST_CURRENCY_PAIR => 'BTCCAD';

use constant TEST_TICKER        => 1;
use constant TEST_TRADEBOOK     => 1;
use constant TEST_ORDERBOOK     => 1;

use constant TEST_PRIVATE       => 0;

use constant TEST_BALANCE       => 1;
use constant TEST_TRANSACTIONS  => 1;
use constant TEST_TRADE_HISTORY => 1;
use constant TEST_ORDER_HISTORY => 1;
use constant TEST_ORDER         => 1;
use constant TEST_ORDER_CANCEL  => 1;
# If you really want to do this test, then set the EXTERNAL_BITCOIN_ADDRESS to something as well...
use constant TEST_WITHDRAW      => 0;
use constant EXTERNAL_BITCOIN_ADDRESS => 'set to your own btc wallet address outside CaVirtex';


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
            currencypair => 'BTCCAD',
        },
    },
    {
        name   => 'Orderbook',
        method => 'orderbook',
        active => TEST_ORDERBOOK,
        params => {
            currencypair => 'BTCCAD',
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
        name   => 'Transaction',
        method => 'transactions',
        active => TEST_TRANSACTIONS,
        params => {
            currencypair => 'BTCCAD',
        },
    },
    {
        name   => 'Trade History',
        method => 'trade_history',
        active => TEST_TRADE_HISTORY,
        params => {
            currencypair => 'BTCCAD',
        },
    },
    {
        name   => 'Order History',
        method => 'order_history',
        active => TEST_ORDER_HISTORY,
        params => {
            currencypair => 'BTCCAD',
        },
    },
    {
        name   => 'Order',
        method => 'order',
        active => TEST_ORDER,
        params => {
            currencypair => 'BTCCAD',
            mode         => 'buy',
            amount       => '0.0001',
            price        => '65.01',
        },
    },
];
=cut
    {
        name   => 'Order Cancel',
        method => 'order_cancel',
        active => TEST_ORDER_CANCEL,
    },
    {
        name   => 'Withdraw',
        method => 'withdraw',
        active => TEST_WITHDRAW,
    },
=cut

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
            skip $name . ' test turned OFF', 1 unless $active;
            unless ($self->$method($self->api->$method($params ? (%$params) : ()))) {
                diag(sprintf "Error is: %s\n", Dumper $self->api->error);
            }
            ok($self->$method, 'request public ' . lc $name);
            print Data::Dumper->Dump([$self->$method],[$name]) if DEBUG;
        }
    }
    say '=== End PUBLIC tests' if VERBOSE;

    say '=== Begin PRIVATE tests' if VERBOSE;
    isa_ok($self->set_private, PACKAGE);
    foreach my $test (@{PRIVATE_TESTS()}) {
        SKIP: {
            my ($name, $method, $active, $params) = @{$test}{qw(name method active params)};
            skip $name . ' test turned OFF', 1 unless TEST_PRIVATE and $active;
            unless ($self->$method($self->api->$method($params ? (%$params) : ()))) {
                diag(sprintf "Error is: %s\n", Dumper $self->api->error);
            }
            ok($self->$method, 'request private ' . $name);
            print Data::Dumper->Dump([$self->$method],[$name]) if DEBUG;
        }
    }
    say '=== End PRIVATE tests' if VERBOSE;

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

    if (TEST_PRIVATE) {
        say '=== Begin PRIVATE tests';
        $self->set_private;
        ## this is a bad trick...
        #$self->{api} = Finance::CaVirtex::API->new(
            #token  => API_TOKEN,
            #secret => API_SECRET,
        #);

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
}

sub set_public  { shift->api(Finance::CaVirtex::API->new) }
sub set_private { shift->api(Finance::CaVirtex::API->new(secret => API_SECRET, token => API_TOKEN)) }

sub api           { get_set(@_) }
sub ticker        { get_set(@_) }
sub tradebook     { get_set(@_) }
sub orderbook     { get_set(@_) }
sub balance       { get_set(@_) }
sub transactions  { get_set(@_) }
sub trade_history { get_set(@_) }
sub order_history { get_set(@_) }
sub order         { get_set(@_) }
sub order_cancel  { get_set(@_) }
sub withdraw      { get_set(@_) }

sub get_set {
   my $self      = shift;
   my $attribute = ((caller(1))[3] =~ /::(\w+)$/)[0];
   $self->{$attribute} = shift if scalar @_;
   return $self->{$attribute};
}

1;

__END__

