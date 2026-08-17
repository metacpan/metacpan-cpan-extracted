use strict;
use warnings;
use Test::More;

use HTTP::API::Core;
use HTTP::API::Core::Auth ();
use HTTP::API::Core::Error;
use HTTP::API::Core::Pagination;
use HTTP::API::Core::RateLimit;
use HTTP::API::Core::Response;

can_ok 'HTTP::API::Core', qw(
    new base_url timeout retry hooks
    request get post put patch delete paginate
);

can_ok 'HTTP::API::Core::Pagination', qw(new next all);

can_ok 'HTTP::API::Core::Response', qw(
    new status reason headers header content text has_content
    content_type is_json json method url elapsed request_id rate_limit
);

can_ok 'HTTP::API::Core::Error', qw(
    new category message method url status retryable retry_after response
    body text json headers header elapsed request_id rate_limit as_string
);

can_ok 'HTTP::API::Core::RateLimit', qw(
    new from_headers limit remaining used resource reset reset_epoch
    retry_after source exhausted wait_seconds as_hash
);

can_ok 'HTTP::API::Core::Auth', qw(
    bearer_auth basic_auth api_key_auth
);

my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test/',
    timeout  => 3,
    transport => sub {
        my ($method, $url, $options) = @_;
        return {
            status  => 200,
            reason  => 'OK',
            headers => { 'Content-Type' => 'application/json' },
            content => '{}',
        };
    },
);

isa_ok $api, 'HTTP::API::Core';
is $api->base_url, 'https://api.example.test', 'constructor keeps normalized base_url accessor';
is $api->timeout, 3, 'constructor keeps timeout accessor';

my $response = $api->get('/contract');
isa_ok $response, 'HTTP::API::Core::Response';
is $response->status, 200, 'request helpers keep returning response objects';
is_deeply $response->json, {}, 'response json accessor remains available';

done_testing;
