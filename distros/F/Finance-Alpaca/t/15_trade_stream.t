use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);
my $clock = $alpaca->clock;
SKIP: {
    skip 'Market is closed' if !$clock->is_open;
    my $client_order_id = 'my_client_order_id#' . Time::HiRes::time();
    my $stream          = $alpaca->trade_stream(
        sub {
            my ($packet) = @_;
            if ( $packet->order->client_order_id eq $client_order_id && $packet->event eq 'fill' ) {
                pass sprintf '[%s] Order %s @ $%f', $packet->order->symbol, $packet->order->status,
                    $packet->order->filled_avg_price;
                done_testing;
                exit;
            }
        }
    );
    Mojo::IOLoop->timer(
        5 => sub {
            isa_ok(
                $alpaca->create_order(
                    symbol          => 'MSFT',
                    qty             => .1,
                    side            => 'buy',
                    type            => 'market',
                    time_in_force   => 'day',
                    client_order_id => $client_order_id
                ),
                'Finance::Alpaca::Struct::Order'
            );
        }
    );
    Mojo::IOLoop->timer(
        30 => sub {
            fail('Timeout after 30s');
            done_testing;
            exit;
        }
    );
    Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
}
done_testing;
1;
