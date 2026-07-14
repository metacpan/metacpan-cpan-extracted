use strict;
use warnings;
use Test::More;
use Test::LWP::UserAgent;
use HTTP::Response;
use JSON::MaybeXS qw(encode_json);

# Mock Google::Auth for hermetic unit testing
package Google::Auth;
$INC{'Google/Auth.pm'} = 1;
sub get_application_default { bless {}, shift }
sub default { bless {}, shift }
sub fetch_token { 'mock-token-abc' }
sub get_token { 'mock-token-abc' }

package main;

use Google::Api::Common;
use Google::Cloud::Bigquery::V2;
use Google::Cloud::REST::Client;

subtest 'BigQuery Client REST Transport Initialization' => sub {
    my $client = Google::Cloud::Bigquery::V2->new(
        credentials => bless({}, 'Google::Auth'),
        transport   => 'rest',
    );

    ok($client, 'Created BigQuery client with REST transport');
    isa_ok($client->transport, 'Google::Cloud::REST::Client');
    is($client->transport->target, 'bigquery.googleapis.com', 'REST target is bigquery.googleapis.com');
};

subtest 'BigQuery Client REST API Request' => sub {
    my $mock_ua = Test::LWP::UserAgent->new;
    $mock_ua->map_response(
        sub { 1 },
        HTTP::Response->new(
            200, 'OK',
            ['Content-Type' => 'application/json'],
            encode_json({ kind => 'bigquery#datasetList' })
        )
    );

    my $rest_client = Google::Cloud::REST::Client->new(
        target     => 'bigquery.googleapis.com',
        auth_token => 'mock-token-abc',
        ua         => $mock_ua,
    );

    my $res = $rest_client->request(
        method => 'GET',
        path   => '/bigquery/v2/projects/my-proj/datasets',
    );

    ok($res, 'Received response from mock REST client');
    is($res->{kind}, 'bigquery#datasetList', 'Parsed JSON response body matches');
};

done_testing();
