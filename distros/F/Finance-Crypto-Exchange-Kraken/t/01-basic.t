use strict;
use warnings;
use Test::More 0.96;
use Sub::Override;
use HTTP::Response;
use JSON;
use Test::Deep;
use Test::Exception;
use MIME::Base64 qw(encode_base64url);

use_ok("Finance::Crypto::Exchange::Kraken");

my $secret = encode_base64url('bar');

my $kraken = Finance::Crypto::Exchange::Kraken->new(
    key    => 'foo',
    secret => $secret,
);

my $data = { error => [], result => { 'some' => 'data' } };

my $request;
my $override = Sub::Override->new(
    'LWP::UserAgent::send_request' => sub {
        my $self = shift;
        $request = shift;
        my $json = JSON::encode_json($data);
        return HTTP::Response->new(200, 'OK', [], $json);
    },
);

my $nonce = "100000";
$override->override(
    'Finance::Crypto::Exchange::Kraken::nonce' => sub { return $nonce });

## Test data

my %market_data = (
    get_server_time   => undef,
    get_system_status => undef,
    get_asset_info  => [
        undef,
        {
            info   => 'info',
            aclass => 'currency',
            asset  => 'all',
        }
    ],
    get_tradable_asset_pairs => [
        undef,
        {
            info => 'info',    #alternatives: leverage, fees, margin
            pair => 'all',
        }
    ],
    get_ticker_information => { pair => 'all' },
    get_ohlc_data          => { pair => 'all', interval => 15 },
    get_order_book         => [
        { pair => 'all' },
        { pair => 'all', count => 12 }
    ],
    get_recent_trades      => { pair => 'all' },
    get_recent_spread_data => { pair => 'all' },
);

my %user_data = (
    get_account_balance => undef,
    get_trade_balance   => [
        undef,
        {
            aclass => 'currency',
            asset  => 'ZUSD',
        },
    ],
    get_open_orders => [
        undef,
        {
            trades  => 1,
            userref => 1,
        },
    ],
    get_closed_orders => [
        { ofs => 1 },
        {
            ofs       => 2,
            userref   => 1,
            start     => 123,
            end       => 123,
            closetime => 'both',
        },
    ],
    query_orders_info => [
        undef,
        {
            trades  => 1,
            userref => 1,
            txid    => '1,2,3',
        },
    ],
    get_trades_history => [
        { ofs => 1 },
        {
            ofs    => 1,
            trades => 1,
            start  => 1,
            end    => 1,
        },
    ],
    query_trades_info     => undef,
    get_open_positions    => undef,
    get_ledger_info       => undef,
    query_ledgers         => undef,
    get_trade_volume      => undef,
    request_export_report => undef,
    get_export_status     => undef,
    get_export_report     => undef,
    remove_export_report  => undef,
);

my %user_trading = (
    add_standard_order => undef,
    cancel_open_order  => undef,
);

my %user_funding = (
    get_deposit_methods          => undef,
    get_deposit_addresses        => undef,
    get_recent_deposit_status    => undef,
    get_withdrawal_info          => undef,
    withdraw_funds               => undef,
    get_recent_withdrawal_status => undef,
    request_withdrawal_cancel    => undef,
    wallet_transfer              => undef,
);

## Actual test runs

_test_methods('Market data',          'public',  %market_data);
_test_methods('Private user data',    'private', %user_data);
_test_methods('Private user trading', 'private', %user_trading);
_test_methods('Private user funding', 'private', %user_funding);
_test_private_method('get_websockets_token');

## Tests methods

sub _test_methods {
    my ($test_name, $type, %tests) = @_;

    subtest $test_name => sub {

        my $test_method = sprintf("_test_%s_method", $type);

        foreach my $method (sort keys %tests) {
            no strict qw(refs);
            my $tests = $tests{$method};
            if (ref $tests eq 'ARRAY') {
                foreach (@$tests) {
                    $test_method->($method, $_);
                }
            }
            else {
                $test_method->($method, $tests);
            }
            use strict;
        }
    }
}

sub _test_public_method {
    my ($method, $payload) = @_;

    _test_method(
        $method, $payload,
        sub {

            is($request->headers->header('api-key'),
                undef, "API key is missing for public method");

            my $uri = $request->uri;
            $uri->query($request->content);
            cmp_deeply(
                { $uri->query_form },
                $payload // {},
                "Correct content send"
            );
        }
    );

}

sub _test_private_method {
    my ($method, $payload) = @_;

    _test_method(
        $method, $payload,
        sub {

            is($request->headers->header('api-key'),
                'foo', "API key is present for private method");

            my $uri = $request->uri;
            $uri->query($request->content);

            cmp_deeply(
                { $uri->query_form },
                { %{ $payload // {} }, nonce => $nonce },
                "Correct content send, including nonce"
            );
        }
    );
    $nonce++;
}

sub _test_method {
    my ($method, $payload, $test) = @_;

    subtest $method => sub {

        can_ok($kraken, $method);
        my $msg = "Got a successful answer from the server: $method";
        if ($payload) {
            $msg .= " with payload";
        }

        my $response;
        lives_ok(
            sub {
                $response = $kraken->$method($payload ? %$payload : ());
            },
            $msg
        );

        isa_ok($response, "HASH", "Got the JSON back from the server");

        $test->();
    }
}


done_testing;
