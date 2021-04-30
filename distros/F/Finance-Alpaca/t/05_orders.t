use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);
my $order = $alpaca->create_order(
    symbol        => 'MSFT',
    qty           => .1,
    side          => 'buy',
    type          => 'market',
    time_in_force => 'day'
);
isa_ok( $order, 'Finance::Alpaca::Struct::Order' );
done_testing;
1;
