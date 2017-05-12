#!/usr/bin/env perl

use Test::Most;
use Test::Mock::LWP;
use Finance::Dogecoin::API;

exit main( @ARGV );

sub main {
    test_constructor_no_apikey();
    test_withdraw_missing_params();
    test_withdraw_invalid_amount();
    test_get_address_received_missing_params();
    test_get_address_by_label_missing_params();
    test_bad_query_exception();

    done_testing;
    return 0;
}

sub test_constructor_no_apikey {
    throws_ok { Finance::Dogecoin::API->new }
        qr/Missing required arguments: api_key/,
        'API constructor should require api_key argument';
}

sub test_withdraw_missing_params {
    my $api = Finance::Dogecoin::API->new( api_key => 'hello, world' );

    throws_ok { $api->withdraw }
        qr/Must call withdraw\(\) with.+\bpayment_address\b.+params/,
        'withdraw() should throw error without payment_address param';

    throws_ok { $api->withdraw }
        qr/Must call withdraw\(\) with.+\bamount\b.+params/,
        'withdraw() should throw error without amount param';

    throws_ok { $api->withdraw( payment_address => '111 North Avenue' ) }
        qr/Must call withdraw\(\) with amount params/,
        '... but should accept a provided payment_address param';

    throws_ok { $api->withdraw( amount => '222' ) }
        qr/Must call withdraw\(\) with payment_address params/,
        '... but should accept a provided amount param';
}

sub test_withdraw_invalid_amount {
    my $api = Finance::Dogecoin::API->new( api_key => 'hello, world' );

    throws_ok { $api->withdraw( payment_address => 'None', amount => 1 ) }
        qr/Must call withdraw\(\) with amount of at least 5 Doge/,
        'withdraw() requires an amount of at least 5 Doge';

    throws_ok { $api->withdraw( payment_address => 'None', amount => 4.99 ) }
        qr/Must call withdraw\(\) with amount of at least 5 Doge/,
        'withdraw() requires an amount of at least 5 Doge';
}

sub test_get_address_received_missing_params {
    my $api = Finance::Dogecoin::API->new( api_key => 'hello, world' );

    throws_ok { $api->get_address_received }
        qr/Must call get_address_received\(\) with payment_address param/,
        'get_address_received() should throw error without payment_address';
}

sub test_get_address_by_label_missing_params {
    my $api = Finance::Dogecoin::API->new( api_key => 'hello, world' );

    throws_ok { $api->get_address_by_label }
        qr/Must call get_address_by_label\(\) with address_label param/,
        'get_address_by_label() should throw error without address_label';
}

sub test_bad_query_exception {
    my $api = Finance::Dogecoin::API->new(
        ua      => $Mock_ua,
        api_key => 'hello, world',
    );

    $Mock_ua->mock(                   get => sub { $Mock_response } );
    $Mock_response->mock( decoded_content => sub { '"Bad Query"'  } );

    my @errors;
    local *Carp::croak;
    *Carp::croak = sub { push @errors, $_[0]; };

    $api->get_address_by_label;
    like $errors[-1], qr/Bad API call from get_address_by_label\(\) call/,
        'API calls should throw exception when remote API fails';

    $Mock_response->mock( decoded_content => sub { '"Invalid API Key"'  } );

    $api->get_balance;
    like $errors[-1], qr/Invalid API key 'hello, world'/,
        'API calls should throw exception with invalid API key';
}
