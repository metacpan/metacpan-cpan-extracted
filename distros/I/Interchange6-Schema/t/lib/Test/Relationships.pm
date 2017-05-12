package Test::Relationships;

use Test::Exception;
use Test::Roo::Role;

test 'Address, OrderlinesShipping and Shipment delete tests' => sub {

    my $self   = shift;
    my $schema = $self->ic6s_schema;

    # prereqs
    $self->addresses unless $self->has_addresses;
    $self->orders    unless $self->has_orders;

    my ( $customer, $shipping_address, $billing_address, $order, $orderline,
        $shipment, $carrier, $orderlines_shipping );

    #
    # tests for Address resultset
    #

    lives_ok(
        sub { $customer = $self->users->find( { username => 'customer2' } ) },
        "find customer2 (this customer has states_id set in all addresses)"
    );

    ok( defined $customer, "we have a customer" );

    lives_ok( sub { $order = $customer->orders->first },
        "find customer order" );

    ok( defined $order, "we have an order" );

    lives_ok( sub { $billing_address = $order->billing_address; },
        "find the billing address" );

    ok( defined $billing_address, "we have a billing address" );

    cmp_ok( $billing_address->orders->count,
        '==', 1, "billing address has 1 order" );

    ok( defined $billing_address->state, "billing address has state" );

    lives_ok( sub { $shipping_address = $order->shipping_address; },
        "find the shipping address" );

    ok( defined $shipping_address, "we have a shipping address" );

    ok( defined $shipping_address->state, "shipping address has state" );

    cmp_ok( $shipping_address->orderlines_shipping->count,
        '==', 0, "shipping address has 0 orderlines_shipping" );

    cmp_ok( $shipping_address->orderlines->count,
        '==', 0, "shipping address has 0 orderlines" );

    lives_ok( sub { $orderline = $order->orderlines->first },
        "find an orderline" );

    ok( defined $orderline, "we have an orderline" );

    lives_ok( sub { $carrier = $self->shipment_carriers->first },
        "find a carrier" );

    ok( defined $carrier, "we have a carrier" );

    lives_ok(
        sub {
            $shipment = $schema->resultset("Shipment")->create(
                {
                    shipment_methods_id =>
                      $carrier->shipment_methods->first->id,
                    tracking_number      => '123456789ABC',
                    shipment_carriers_id => $carrier->id,
                }
            );
        },
        "create a shipment"
    );

    ok( defined $shipment, "we have a shipment" );

    lives_ok(
        sub {
            $orderlines_shipping = $orderline->create_related(
                'orderlines_shipping',
                {
                    addresses_id => $shipping_address->id,
                    shipments_id => $shipment->id,
                    quantity     => 1,
                }
            );
        },
        "create orderlines_shipping row for this orderline/shipment"
    );

    ok( defined $orderlines_shipping, "we got the orderlines_shipping row" );

    cmp_ok( $shipping_address->orderlines_shipping->count,
        '==', 1, "shipping address has 1 orderlines_shipping" );

    cmp_ok( $shipping_address->orderlines->count,
        '==', 1, "shipping address has 1 orderline" );

    # save counts for all relationships of Address so we can check against
    # these later
    my $num_addresses = $self->addresses->count;
    my $num_orderlines_shipping =
      $schema->resultset('OrderlinesShipping')->count;
    my $num_orders     = $self->orders->count;
    my $num_users      = $self->users->count;
    my $num_states     = $self->states->count;
    my $num_countries  = $self->countries->count;
    my $num_orderlines = $schema->resultset('Orderline')->count;
    my $num_shipments  = $schema->resultset('Shipment')->count;

    ok( !$billing_address->archived, "billing address is NOT archived" );
    lives_ok( sub { $billing_address->delete },
        "try to delete billing address" );
    ok( $billing_address->archived, "billing address IS archived" );

    ok( !$shipping_address->archived, "shipping address is NOT archived" );
    lives_ok( sub { $shipping_address->delete },
        "try to delete shipping address" );
    ok( $shipping_address->archived, "shipping address IS archived" );

    my $unused_address;

    lives_ok(
        sub {
            $unused_address = $customer->create_related(
                'addresses',
                {
                    type             => "unused",
                    country_iso_code => 'MT',
                }
            );
        },
        "create an unused address that we should be able to delete"
    );

    isa_ok(
        $unused_address,
        "Interchange6::Schema::Result::Address",
        "we have an address"
    );

    lives_ok( sub { $unused_address->delete }, "delete unused address" );

    # check counts are as we expect
    cmp_ok( $self->addresses->count,
        '==', $num_addresses, "count of addresses has not changed" );
    cmp_ok( $schema->resultset('OrderlinesShipping')->count,
        '==', $num_orderlines_shipping,
        "count of orderlines_shipping has not changed" );
    cmp_ok( $self->orders->count, '==', $num_orders,
        "count of orders has not changed" );
    cmp_ok( $self->users->count, '==', $num_users,
        "count of users has not changed" );
    cmp_ok( $self->states->count, '==', $num_states,
        "count of states has not changed" );
    cmp_ok( $self->countries->count,
        '==', $num_countries, "count of countries has not changed" );
    cmp_ok( $schema->resultset('Orderline')->count,
        '==', $num_orderlines, "count of orderlines has not changed" );
    cmp_ok( $schema->resultset('Shipment')->count,
        '==', $num_shipments, "count of shipments has not changed" );

    #
    # tests for Shipment
    #

    throws_ok( sub { $shipment->delete },
        qr/failed/, "deleting the Shipment row fails" );

    #
    # tests for OrderlinesShipping
    #

    throws_ok(
        sub { $orderlines_shipping->delete },
        qr/cannot be deleted/i,
        "normal delete of the orderlines_shipping row fails"
    );

    # cleanup
    $self->clear_orders;
};

1;
