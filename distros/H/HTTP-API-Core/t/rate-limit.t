use strict;
use warnings;
use Test::More;

use HTTP::API::Core;
use HTTP::API::Core::RateLimit;
use HTTP::API::Core::Response;

my $standard = HTTP::API::Core::RateLimit->from_headers({
    'RateLimit-Limit'     => '100',
    'RateLimit-Remaining' => '0',
    'RateLimit-Reset'     => '12',
    'Retry-After'         => '7',
});

is $standard->limit, 100, 'RateLimit limit parsed';
is $standard->remaining, 0, 'RateLimit remaining parsed';
is $standard->reset, 12, 'RateLimit reset delay parsed';
is $standard->retry_after, 7, 'Retry-After parsed';
ok $standard->exhausted, 'zero remaining is exhausted';
is $standard->wait_seconds(now => 1000), 7, 'Retry-After takes precedence';

my $github_style = HTTP::API::Core::RateLimit->from_headers({
    'X-RateLimit-Limit'     => '5000',
    'X-RateLimit-Remaining' => '0',
    'X-RateLimit-Used'      => '5000',
    'X-RateLimit-Reset'     => '1100',
    'X-RateLimit-Resource'  => 'core',
});

is $github_style->limit, 5000, 'X-RateLimit limit parsed';
is $github_style->used, 5000, 'X-RateLimit used parsed';
is $github_style->resource, 'core', 'rate limit resource parsed';
is $github_style->reset_epoch, 1100, 'epoch reset parsed';
is $github_style->wait_seconds(now => 1000), 100, 'epoch reset converted to wait seconds';
is $github_style->wait_seconds(now => 1200), 0, 'past epoch reset clamps to zero';

my $response = HTTP::API::Core::Response->new(
    status => 200,
    reason => 'OK',
    headers => {
        'X-RateLimit-Limit' => '60',
        'X-RateLimit-Remaining' => '42',
        'X-RateLimit-Reset' => '2000',
    },
    content => '{}',
    method => 'GET',
    url => 'https://api.example.test/items',
);

isa_ok $response->rate_limit, 'HTTP::API::Core::RateLimit';
is $response->rate_limit->remaining, 42, 'response exposes normalized metadata';
ok !$response->rate_limit->exhausted, 'positive remaining is not exhausted';

my $calls = 0;
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => {
        attempts => 2,
        base_delay => 0,
        max_delay => 0,
        jitter => 0,
    },
    transport => sub {
        $calls++;
        return {
            status => 403,
            reason => 'rate limited',
            headers => {
                'RateLimit-Remaining' => '0',
                'RateLimit-Reset' => '0',
            },
            content => '{}',
        } if $calls == 1;

        return {
            status => 200,
            reason => 'OK',
            headers => { 'RateLimit-Remaining' => '10' },
            content => '{"ok":true}',
        };
    },
);

my $retried = $api->get('/limited');
is $retried->status, 200, '403 exhausted quota is retried';
is $calls, 2, 'rate limited request retried once';

my $error_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    transport => sub {
        return {
            status => 429,
            reason => 'Too Many Requests',
            headers => {
                'X-RateLimit-Limit' => '100',
                'X-RateLimit-Remaining' => '0',
                'X-RateLimit-Reset' => '1',
            },
            content => '{}',
        };
    },
);

my $error;
eval { $error_api->get('/limited'); 1 } or $error = $@;
isa_ok $error, 'HTTP::API::Core::Error';
isa_ok $error->rate_limit, 'HTTP::API::Core::RateLimit';
is $error->rate_limit->remaining, 0, 'errors expose rate limit metadata';

done_testing;
