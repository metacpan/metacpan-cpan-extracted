#!/usr/bin/env perl

use 5.010;

use JSON;
use Test::Most;
use Test::Mock::LWP;
use Finance::Dogecoin::API;

exit main( @ARGV );

sub main {
    my $api = Finance::Dogecoin::API->new(
        ua      => $Mock_ua,
        api_key => 'foobar',
    );

    $Mock_ua->mock( get => sub { $Mock_response } );

    test_get_difficulty(       $api );
    test_get_current_block(    $api );
    test_get_current_price(    $api );
    test_get_balance(          $api );
    test_get_my_addresses(     $api );
    test_withdraw(             $api );
    test_get_new_address(      $api );
    test_get_address_received( $api );
    test_get_address_by_label( $api );

    done_testing;
    return 0;
}

sub make_json_response {
    state $json = do { my $j = JSON->new; $j->allow_nonref; $j };
    my $datum   = shift;
    $Mock_response->mock( decoded_content => sub { $json->encode( $datum ) } );
}

sub test_get_difficulty {
    my $api = shift;

    make_json_response( 1281.08277983 );
    is $api->get_difficulty, 1281.08277983,
        'get_difficulty() should return JSON decoded result';
}

sub test_get_current_block {
    my $api = shift;

    make_json_response( 75268 );
    is $api->get_current_block, 75268,
        'get_current_block() should return JSON decoded result';
}

sub test_get_current_price {
    my $api = shift;

    make_json_response( 0.0014510097 );
    is $api->get_current_price, 0.0014510097,
        'get_current_price() should return JSON decoded result';
}

sub test_get_balance {
    my $api = shift;

    make_json_response( 100.98 );
    is $api->get_balance, 100.98,
        'get_balance() should return JSON decoded result';
}

sub test_get_my_addresses {
    my $api = shift;

    make_json_response( [] );
    is_deeply $api->get_my_addresses, [],
        'get_my_addresses() should return empty arrayref with no addresses';

    make_json_response( [qw( addyone twoaddy addthress ) ] );
    is_deeply $api->get_my_addresses, [qw( addyone twoaddy addthress ) ],
        'get_my_addresses() should return filled arrayref when possible';
}

sub test_withdraw {
    my $api = shift;

    # this isn't a great test; patches welcome
    make_json_response( 'success' );
    is $api->withdraw( payment_address => 'addthreess', amount => 404 ),
        'success',
        'withdraw() should return success on success';
}

sub test_get_new_address {
    my $api = shift;

    make_json_response( 'newaddress1' );
    is $api->get_new_address, 'newaddress1',
        'get_new_address() should return new address decoded from JSON';
}

sub test_get_address_received {
    my $api = shift;

    make_json_response( 888.77 );
    is $api->get_address_received( address_label => 'newaddress1' ), 888.77,
        'get_address_received() should return value decoded from JSON';

    make_json_response( 777.88 );
    is $api->get_address_received( payment_address => '1234abcd' ), 777.88,
        'get_address_received() should return value decoded from JSON';
}

sub test_get_address_by_label {
    my $api = shift;

    make_json_response( '1234abcd' );
    is $api->get_address_by_label( address_label => 'newaddress1' ),
        '1234abcd',
        'get_address_by_label() should return address decoded from JSON';
}
