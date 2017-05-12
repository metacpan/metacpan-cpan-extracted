package Test::Expire;

use Test::Exception;
use Test::MockTime qw( :all );
use Test::Roo::Role;

test 'expire tests' => sub {

    my $self = shift;

    # fixtures

    my ( $ret, $rset, $session, $user, $product );

    my $schema = $self->ic6s_schema;

    my $rs = $schema->resultset('Session');

    my %payment_orders = (
                          '6182808' => undef,
                          '9999999' => undef,
                         );

    # in an earlier time...

    set_absolute_time('2014-06-06T12:00:00Z');

    lives_ok( sub { $user = $self->users->find( { username => 'customer1' } ) },
        "grab a user" );

    lives_ok(
        sub {
            $product = $self->products->search( {}, { rows => 1 } )->first;
        },
        "grab a product"
    );

    # create sessions
    my @pop_session =
      ( [ '6182808', 'Green Banana' ], [ '9999999', 'Red Banana' ] );

    lives_ok(
        sub {
            $ret = $schema->populate( 'Session',
                [ [ 'sessions_id', 'session_data' ], @pop_session, ] );
        },
        "create sessions"
    );

    cmp_ok( $rs->count, '==', '2', "session count == 2" );

    # create carts
    my @pop_cart = (
        [ 'main', $user->id, '6182808' ],
        [ 'main', undef,     '9999999' ]
    );

    lives_ok(
        sub {
            $ret = $schema->populate(
                'Cart',
                [
                    [ 'name', 'users_id', 'sessions_id' ],
                    @pop_cart,
                ]
            );
        },
        "populate Cart"
    );

    my $rs_cart = $schema->resultset('Cart');

    ok( $rs_cart->count eq '2', "Testing cart count." )
      || diag "Cart count: " . $rs_cart->count;

    my $cart1 = $rs_cart->next;
    my $cart2 = $rs_cart->next;

    # create CartProduct
    my @pop_prod = (
        [ $cart1->id, $product->sku, '1', '1' ],
        [ $cart2->id, $product->sku, '1', '12' ]
    );

    # populate CartProduct
    $ret = $schema->populate( 'CartProduct',
        [ [ 'carts_id', 'sku', 'cart_position', 'quantity' ], @pop_prod, ] );

    my $rs_prod = $schema->resultset('Cart');

    ok( $rs_prod->count eq '2', "Testing cart count." )
      || diag "CartProduct count: " . $rs_prod->count;

    foreach my $sid ( keys %payment_orders ) {
        my %insertion = (
            payment_mode   => 'PayPal',
            payment_action => 'charge',
            status         => 'request',
            sessions_id    => $sid,
            amount         => '10.00',
            payment_fee    => 1.00,
        );
        my $payment;
        lives_ok(
            sub {
                $payment =
                  $schema->resultset('PaymentOrder')->create( \%insertion );
            },
            "Insert payment into db"
        );
        $payment->discard_changes;
        ok( $payment->payment_orders_id, "Got a payment_order id for $sid" );
        is( $payment->sessions_id, $sid, "Payment session is $sid" );
        $payment_orders{$sid} = $payment->payment_orders_id;
    }

    # time advances 10 minutes...

    set_absolute_time('2014-06-06T12:10:00Z');

    throws_ok(
        sub { $schema->resultset('Session')->expire() },
        qr/Session expiration not set/,
        "Fail on undef arg to expire"
    );

    throws_ok(
        sub { $schema->resultset('Session')->expire('bananas') },
        qr/Unknown timespec: bananas/,
        "Fail on bad scalar arg to expire"
    );

    # find expired sessions and delete them
    lives_ok( sub { $schema->resultset('Session')->expire('1 second') },
        "Expire with arg '1 second'" );

    # test for expired sessions
    $rs = $schema->resultset('Session');
    ok( $rs->count eq '0', "Testing sessions count." )
      || diag "Sessions count: " . $rs->count;

    # test remaining carts
    my $carts = $schema->resultset('Cart');
    ok( $carts->count() eq '1', "Testing cart count." )
      || diag "Cart count: " . $carts->count();

    foreach my $sid ( keys %payment_orders ) {
        my $payment_id = $payment_orders{$sid};
        my $payment    = $schema->resultset('PaymentOrder')->find($payment_id);
        ok( $payment,         "Found payment $payment_id" );
        ok( $payment->amount, "Found the amount " . $payment->amount );
        ok( !defined( $payment->sessions_id ),
            "Now the payment_order sessions_id is undefined (was $sid)" );
    }

    while ( my $carts_rs = $carts->next ) {
        is( $carts_rs->sessions_id, undef, "undefined as expected" );
    }

    # time goes backwards...

    set_absolute_time('2014-06-06T12:00:00Z');

    lives_ok(
        sub {
            $session = $schema->resultset('Session')->create(
                {
                    sessions_id  => '12345',
                    session_data => 'Yellow banana'
                }
            );
        },
        "Create new session"
    );

    lives_ok( sub { $rset = $schema->resultset('Session')->search( {} ) },
        "Search for session in DB" );

    cmp_ok( $rset->count, '==', 1, "1 session found" );
    $session = $rset->next;

    lives_ok( sub { $rset = $schema->resultset('Cart')->search( {} ) },
        'Find carts' );

    lives_ok(
        sub {
            $rset->next->update( { sessions_id => $session->sessions_id } );
        },
        "Attach active session to first cart"
    );

    lives_ok(
        sub {
            $rset = $schema->resultset('Cart')
              ->search( { sessions_id => { '!=', undef } } );
        },
        "Find carts where sessions_id is not undef"
    );

    cmp_ok( $rset->count, '==', 1, "found 1" );

    # time advances again...

    set_absolute_time('2014-06-06T12:10:00Z');

    lives_ok( sub { $schema->resultset('Session')->expire('1') },
        "Expire with arg '1'" );

    lives_ok(
        sub {
            $rset = $schema->resultset('Cart')
              ->search( { sessions_id => { '!=', undef } } );
        },
        "Find carts where sessions_id is not undef"
    );

    cmp_ok( $rset->count, '==', 0, "found 0" );

    # test for expired sessions
    $rs = $schema->resultset('Session');
    ok( $rs->count eq '0', "Testing sessions count." )
      || diag "Sessions count: " . $rs->count;

    # cleanup
    restore_time();

    lives_ok( sub { $schema->resultset('Cart')->delete_all }, "clear Cart" );
    lives_ok( sub { $schema->resultset('Session')->delete_all },
        "clear Session" );
    lives_ok( sub { $schema->resultset('PaymentOrder')->delete_all },
              "clear PaymentOrder" );
    $self->clear_users;
};

1;
