use strict;
use Test2::V0;
use lib '../lib', './lib';
#
use Finance::Alpaca;
my $alpaca = Finance::Alpaca->new(
    paper => 1,
    keys  => [ 'PKZBFZQFCKV2QLTVIGLA', 'HD4LPxBHTUTjwxR6SBeOX1rIiWHRHPDdbv7n2pI0' ]
);

# Count our unexecuted orders
my $tally = scalar $alpaca->orders( status => 'open' );

# Next, create an order that will likely never execute
my $order = $alpaca->create_order(
    symbol          => 'MSFT',
    qty             => 1,
    side            => 'buy',
    type            => 'limit',
    limit_price     => 1,
    time_in_force   => 'gtc',
    client_order_id => 'test order #' . Time::HiRes::time()
);
SKIP: {
    skip 'Failed to place an order! Race cond likely' unless $order;
    isa_ok( $order, 'Finance::Alpaca::Struct::Order' );
    my @orders = $alpaca->orders( status => 'open' );

    # Just make sure we have more rather than +1; race cond with smokers
    is( $order->id, $alpaca->order_by_id( $order->id )->id, 'Retrieve order by id' );
    is(
        $order->id,
        $alpaca->order_by_client_id( $order->client_order_id )->id,
        'Retrieve order by client_id'
    );

    # Make original order larger
    my $replacement = $alpaca->replace_order( $order->id, qty => 50 );
SKIP: {
        if ( ref $replacement eq 'HASH' && defined $replacement->{code} ) {
            skip ucfirst $replacement->{message};
            $order->cancel;    # Just cancel it and move on
        }

        # Gather original with updated stats
        $order = $alpaca->order_by_id( $order->id );
        is( $order->replaced_by,    $replacement->id, 'Order replaced' );
        is( $replacement->replaces, $order->id,       'Both sides have references' );
        ok( $alpaca->cancel_order( $replacement->id ), 'Cancel replacement' );
        like(
            $alpaca->order_by_id( $replacement->id )->status,
            qr[^canceled|pending_cancel$], 'Canceled order status is correct'
        );
    }
}
#
done_testing;
1;
