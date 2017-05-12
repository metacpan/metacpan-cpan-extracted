package Test::Shipment;

use Test::Exception;
use Test::Roo::Role;

use DateTime;

test 'shipment tests' => sub {

    my $self = shift;

    my (
        $rset,     %countries, %states,  %zones,
        $data,     $result,    $product, $order,
        $orderline
    );


    my $schema = $self->ic6s_schema;

    # grab a few things from fixtures

    my $nys = $self->states->find( { state_iso_code => 'NY' } );

    my $user = $self->users->find( { username => 'customer1' } );

    my $billing_address =
      $self->addresses->search( { users_id => $user->id, type => 'billing' } )
      ->first;

    my $shipping_address =
      $self->addresses->search( { users_id => $user->id, type => 'shipping' } )
      ->first;

    my %carrier;

    lives_ok(
        sub {
            $carrier{UPS} = $self->shipment_carriers->search( { name => 'UPS' },
                { rows => 1 } )->single;
        },
        "grab carrier UPS"
    );
    cmp_ok( $carrier{UPS}->account_number,
        'eq', '1U99999', "check account number" );

    lives_ok(
        sub {
            $carrier{KISS} =
              $self->shipment_carriers->search( { name => 'KISS' },
                { rows => 1 } )->single;
        },
        "grab carrier KISS"
    );
    cmp_ok( $carrier{KISS}->account_number,
        'eq', '1K99999', "check account number" );

    my $shipment_method;
    lives_ok(
        sub {
            $shipment_method = $schema->resultset("ShipmentMethod")
              ->find( { title => 'Ground Residential' } );
        },
        "find Ground Residential"
    );

    cmp_ok( $shipment_method->name, 'eq', 'GNDRES', "check name" );

    my $shipment_rate = $self->shipment_rates->find(
        { shipment_methods_id => $shipment_method->id } );

    # ugly use of sprintf as SQLite uses float for numeric which can break test
    cmp_ok( sprintf("%.02f", $shipment_rate->price), '==', 9.95,
        "Testing flat rate shipping price for UPS Ground lower 48 states." );

    lives_ok( sub { $product = $self->products->first }, "grab a product" );

    my $shipping_address_id = $shipping_address->id;
    my $billing_address_id  = $billing_address->id;

    # partial shipments

    lives_ok(
        sub {
            $order = $schema->resultset("Order")->create(
                {
                    order_number          => 'IC60001',
                    users_id              => $user->users_id,
                    email                 => $user->email,
                    shipping_addresses_id => $shipping_address_id,
                    billing_addresses_id  => $billing_address_id,
                    order_date            => DateTime->now,
                    orderlines            => [
                        {
                            order_position => '1',
                            sku            => $product->sku,
                            name           => $product->name,
                            description    => $product->description,
                            weight         => $product->weight,
                            quantity       => 2,
                            price          => 123,
                            subtotal       => 246,
                            shipping       => 7.95,
                            handling       => 1.95,
                            salestax       => 63.36,
                        },
                    ],
                }
            );
        },
        "Create order IC60001"
    );

    $orderline = $order->orderlines->first;

    cmp_ok( $orderline->sku, 'eq', $product->sku,
        "Testing Orderline record creation." );

    lives_ok {
        $result = $schema->resultset("Shipment")->create(
            {
                shipment_methods_id  => $shipment_method->id,
                tracking_number      => '1Z99283WNMS984920498320',
                shipment_carriers_id => $carrier{UPS}->id,
            }
          )
    }
    "Create 1st partial shipment";

    lives_ok {
          $schema->resultset("OrderlinesShipping")->create(
            {
                orderlines_id => $orderline->id,
                addresses_id  => $shipping_address->id,
                shipments_id  => $result->id,
                quantity      => 1,
            }
          )
    }
    "create orderlines_shipping for quantity 1";

    lives_ok {
        $result = $schema->resultset("Shipment")->create(
            {
                shipment_methods_id  => $shipment_method->id,
                tracking_number      => '1Z99283WNMS984920498320',
                shipment_carriers_id => $carrier{UPS}->id,
            }
          )
    }
    "Create 2nd partial shipment";

    lives_ok {
          $schema->resultset("OrderlinesShipping")->create(
            {
                orderlines_id => $orderline->id,
                addresses_id  => $shipping_address->id,
                shipments_id  => $result->id,
                quantity      => 1,
            }
          )
    }
    "create orderlines_shipping for quantity 1";

    # test all relationships

    # find order
    lives_ok {
        $result = $user->find_related( 'orders', { order_number => 'IC60001' } )
    }
    "Find order IC60001";

    cmp_ok $result->orderlines->count, '==', 1, "order IC60001 has 1 orderline";

    lives_ok {
        $rset = $result->orderlines->related_resultset('orderlines_shipping')
    }
    "find related OrderlinesShipping";

    cmp_ok $rset->count, '==', 2, "2 OrderlinesShipping rows";

    cmp_ok $rset->get_column('quantity')->sum, '==', 2,
      "total quantity shipped is 2";

    while ( my $result = $rset->next ) {
        ok $result->partial_shipment, "we have a partial shipment";
    }

    # full shipment

    lives_ok(
        sub {
            $order = $schema->resultset("Order")->create(
                {
                    order_number          => 'IC60002',
                    users_id              => $user->users_id,
                    email                 => $user->email,
                    shipping_addresses_id => $shipping_address_id,
                    billing_addresses_id  => $billing_address_id,
                    order_date            => DateTime->now,
                    orderlines            => [
                        {
                            order_position => '1',
                            sku            => $product->sku,
                            name           => $product->name,
                            description    => $product->description,
                            weight         => $product->weight,
                            quantity       => 2,
                            price          => 123,
                            subtotal       => 246,
                            shipping       => 7.95,
                            handling       => 1.95,
                            salestax       => 63.36,
                        },
                    ],
                }
            );
        },
        "Create order IC60002"
    );

    $orderline = $order->orderlines->first;

    cmp_ok( $orderline->sku, 'eq', $product->sku,
        "Testing Orderline record creation." );

    lives_ok {
        $result = $schema->resultset("Shipment")->create(
            {
                shipment_methods_id  => $shipment_method->id,
                tracking_number      => '1Z99283WNMS984920498320',
                shipment_carriers_id => $carrier{UPS}->id,
            }
          )
    }
    "Create shipment";

    lives_ok {
          $schema->resultset("OrderlinesShipping")->create(
            {
                orderlines_id => $orderline->id,
                addresses_id  => $shipping_address->id,
                shipments_id  => $result->id,
                quantity      => 2,
            }
          )
    }
    "create orderlines_shipping for full quantity";

    # test all relationships

    # find order
    lives_ok {
        $result = $user->find_related( 'orders', { order_number => 'IC60002' } )
    }
    "Find order IC60002";

    cmp_ok $result->orderlines->count, '==', 1, "order IC60002 has 1 orderline";

    lives_ok {
        $rset = $result->orderlines->related_resultset('orderlines_shipping')
    }
    "find related OrderlinesShipping";

    cmp_ok $rset->count, '==', 1, "1 OrderlinesShipping row";

    cmp_ok $rset->get_column('quantity')->sum, '==', 2,
      "total quantity shipped is 2";

    ok !$rset->next->partial_shipment, "we have full shipment";

    # cleanup
    $self->clear_orders;

};

1;
