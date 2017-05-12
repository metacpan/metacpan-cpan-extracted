#!/usr/bin/perl -wT

use 5.010;
use warnings;
use strict;
use lib qw(.);

use Test::More tests => 15;

use Data::Dumper;
use JSON;

use constant DEBUG => 0;

# Enter your BitStamp API key, API secret and BitStamp client ID values here...
use constant KEY       => 'BitStamp API key      goes here';
use constant SECRET    => 'BitStamp API secret   goes here';
use constant CLIENT_ID => 'BitStamp API clientID goes here';

use constant PACKAGE   => 'Finance::BitStamp::API';

# Public Tests...
use constant TEST_TICKER           => 1;
use constant TEST_ORDERBOOK        => 1;
use constant TEST_PUB_TRANSACTIONS => 1;
use constant TEST_CONVERSION_RATE  => 1;

# Private Tests...
use constant TEST_BALANCE          => 1;
use constant TEST_TRANSACTIONS     => 1;
use constant TEST_WITHDRAWALS      => 1;
use constant TEST_RIPPLE_ADDRESS   => 1;
use constant TEST_BITCOIN_ADDRESS  => 1;
use constant TEST_ORDERS           => 1;
use constant TEST_PENDING_DEPOSITS => 1;

# THESE REMAIN TO BE TESTED...
# use constant TEST_BUY               => 0;
# use constant TEST_SELL              => 0;
# use constant TEST_CANCEL            => 0;
# use constant TEST_BITCOINwITHDRAWAL => 0;
# use constant TEST_RIPPLEwITHDRAWAL  => 0;

use constant PUBLIC_TESTS => [
    {
        name   => 'Ticker',
        method => 'ticker',
        active => TEST_TICKER,
    },
    {
        name   => 'OrederBook',
        method => 'orderbook',
        active => TEST_ORDERBOOK,
    },
    {
        name   => 'Transactions',
        method => 'public_transactions',
        active => TEST_PUB_TRANSACTIONS,
    },
    {
        name   => 'Conversion Rate',
        method => 'conversion_rate',
        active => TEST_CONVERSION_RATE,
    },
];

use constant PRIVATE_TESTS => [
    {
        name   => 'Balance',
        method => 'balance',
        active => TEST_BALANCE,
    },
    {
        name   => 'Transactions',
        method => 'transactions',
        active => TEST_TRANSACTIONS,
    },
    {
        name   => 'Withdrawals',
        method => 'withdrawals',
        active => TEST_WITHDRAWALS,
    },
    {
        name   => 'Ripple Address',
        method => 'ripple_address',
        active => TEST_RIPPLE_ADDRESS,
    },
    {
        name   => 'Bitcoin Address',
        method => 'bitcoin_address',
        active => TEST_BITCOIN_ADDRESS,
    },
    {
        name   => 'Orders',
        method => 'orders',
        active => TEST_ORDERS,
    },
    {
        name   => 'Pending Deposits',
        method => 'pending_deposits',
        active => TEST_PENDING_DEPOSITS,
    },
];

BEGIN { use_ok(PACKAGE) };

main->new->go;

sub new         { bless {} => shift }
sub json        { shift->{json}      || JSON->new }
sub bitstamp    { get_set(@_) }
sub set_public  { shift->bitstamp(Finance::BitStamp::API->new) }
sub set_private { shift->bitstamp(Finance::BitStamp::API->new(key => KEY, secret => SECRET, client_id => CLIENT_ID)) }

sub go  {
    my $self = shift;

    can_ok(PACKAGE, qw(new));

    say '=== Begin PUBLIC tests' if DEBUG;
    isa_ok($self->set_public, PACKAGE);
    foreach my $test (@{PUBLIC_TESTS()}) {
        SKIP: {
            my ($name, $method, $active) = @{$test}{qw(name method active)};
            skip $name . ' test turned OFF', 1 unless $active;
            $self->$method($self->bitstamp->$method);
            ok($self->$method, 'request public ' . $name);
            print Data::Dumper->Dump([$self->$method],[$name]) if DEBUG;
        }
    }
    say '=== End PUBLIC tests' if DEBUG;

    say '=== Begin PRIVATE tests' if DEBUG;
    isa_ok($self->set_private, PACKAGE);
    foreach my $test (@{PRIVATE_TESTS()}) {
        SKIP: {
            my ($name, $method, $active) = @{$test}{qw(name method active)};
            skip $name . ' test turned OFF', 1 unless $active;
            $self->$method($self->bitstamp->$method);
            ok($self->$method, 'request private ' . $name);
            print Data::Dumper->Dump([$self->$method],[$name]) if DEBUG;
        }
    }
    say '=== End PRIVATE tests' if DEBUG;
}

sub ticker              { get_set(@_) }
sub orderbook           { get_set(@_) }
sub public_transactions { get_set(@_) }
sub conversion_rate     { get_set(@_) }
sub balance             { get_set(@_) }
sub transactions        { get_set(@_) }
sub withdrawals         { get_set(@_) }
sub ripple_address      { get_set(@_) }
sub bitcoin_address     { get_set(@_) }
sub orders              { get_set(@_) }
sub pending_deposits    { get_set(@_) }

sub get_set {
    my $self      = shift;
    my $attribute = ((caller(1))[3] =~ /::(\w+)$/)[0];
    $self->{$attribute} = shift if scalar @_;
    return $self->{$attribute};
}

1;

__END__

