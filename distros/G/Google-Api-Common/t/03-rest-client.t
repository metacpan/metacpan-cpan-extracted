use strict;
use warnings;
use Test::More;
use Test::LWP::UserAgent;
use HTTP::Response;
use JSON::MaybeXS qw(encode_json);

use Google::Cloud::REST::Client;

subtest 'REST Client Initialization' => sub {
    my $client = Google::Cloud::REST::Client->new(
        target     => 'bigquery.googleapis.com',
        auth_token => 'mock-bearer-token-12345',
    );
    ok($client, 'Created REST client');
    is($client->target, 'bigquery.googleapis.com', 'Target set correctly');
    is($client->auth_token, 'mock-bearer-token-12345', 'Auth token set correctly');
};

subtest 'REST Request Execution with Mock LWP UserAgent' => sub {
    my $mock_ua = Test::LWP::UserAgent->new;
    $mock_ua->map_response(
        sub {
            my $req = shift;
            return $req->url->path eq '/bigquery/v2/projects/test-project/datasets'
                && $req->header('Authorization') eq 'Bearer mock-bearer-token-12345';
        },
        HTTP::Response->new(
            200, 'OK',
            ['Content-Type' => 'application/json'],
            encode_json({ kind => 'bigquery#datasetList', datasets => [{ id => 'ds1' }] })
        )
    );

    my $client = Google::Cloud::REST::Client->new(
        target     => 'bigquery.googleapis.com',
        auth_token => 'mock-bearer-token-12345',
        user_agent => $mock_ua,
    );

    my $res = $client->call({
        method => 'GET',
        path   => 'bigquery/v2/projects/test-project/datasets',
    });

    ok($res, 'Got REST response');
    is($res->{kind}, 'bigquery#datasetList', 'Response kind matches');
    is($res->{datasets}->[0]->{id}, 'ds1', 'Dataset ID matches');
};

done_testing();
