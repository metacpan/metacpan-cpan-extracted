use strict;
use warnings;
use Test::More;
use Test::LWP::UserAgent;
use HTTP::Response;
use JSON::MaybeXS qw(encode_json);

package Google::Auth;
BEGIN { $INC{'Google/Auth.pm'} = 1; }
sub default { bless {}, 'Google::Auth::Mock' }
package Google::Auth::Mock;
sub get_token { 'mock-token-abc' }

package main;
use Google::Api::Common;
use Google::Ai::Generativelanguage::V1;
use Google::Cloud::REST::Client;

subtest 'Client REST Transport Initialization' => sub {
    my $client = Google::Ai::Generativelanguage::V1->new(
        credentials => bless({}, 'Google::Auth::Mock'),
        transport   => 'rest',
    );

    ok($client, 'Created client with REST transport');
    isa_ok($client->transport, 'Google::Cloud::REST::Client');
};

subtest 'Client REST API Request' => sub {
    my $mock_ua = Test::LWP::UserAgent->new;
    $mock_ua->map_response(
        sub { 1 },
        HTTP::Response->new(
            200, 'OK',
            ['Content-Type' => 'application/json'],
            encode_json({ kind => 'response' })
        )
    );

    my $rest_client = Google::Cloud::REST::Client->new(
        target     => 'test.googleapis.com',
        auth_token => 'mock-token-abc',
        ua         => $mock_ua,
    );

    my $res = $rest_client->request(
        method => 'GET',
        path   => '/v1/test',
    );

    ok($res, 'Received response from mock REST client');
};

done_testing();
