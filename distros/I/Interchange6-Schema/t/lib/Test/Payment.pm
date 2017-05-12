package Test::Payment;

use Test::Exception;
use Test::Roo::Role;

test 'payment tests' => sub {

    my $self = shift;

    my $schema = $self->ic6s_schema;

    my $user;

    lives_ok( sub { $user = $self->users->find( { username => 'customer1' } ) },
        "grab user from fixtures" );

    lives_ok(
        sub {
            $schema->resultset("Session")->create(
                {
                    sessions_id  => '123412341234',
                    session_data => '',
                }
            );
        },
        "Create session"
    );

    my %insertion = (
        payment_mode   => 'PayPal',
        payment_action => 'charge',
        status         => 'request',
        sessions_id    => '123412341234',
        amount         => '10.00',
        payment_fee    => 1.00,
        users_id       => $user->id,
    );

    my $payment;
    lives_ok(
        sub {
            $payment =
              $schema->resultset('PaymentOrder')->create( \%insertion );
        },
        "Insert payment into db"
    );

    ok( $payment->payment_fee == 1 );
    my $pid = $payment->payment_orders_id;
    $payment = $schema->resultset('PaymentOrder')->find($pid);
    ok ($payment, "Found the payment");
    my $session = $schema->resultset('Session')->find('123412341234');
    ok ($session, "Session found");
    $session->delete;
    $payment = $schema->resultset('PaymentOrder')->find($pid);
    ok ($payment, "Found the payment after session deletion");

    # cleanup
    lives_ok( sub { $schema->resultset("PaymentOrder")->delete_all },
        "delete_all from PaymentOrder" );
    lives_ok( sub { $schema->resultset("Session")->delete_all },
        "delete_all from Session" );

};

1;
