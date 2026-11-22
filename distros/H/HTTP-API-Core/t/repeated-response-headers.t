use strict;
use warnings;
use Test::More;

use HTTP::API::Core;
use HTTP::API::Core::Response;
use HTTP::API::Core::RateLimit;
use HTTP::API::Core::Error;

# These tests make no network requests. Ignore inherited proxy settings so
# HTTP::Tiny construction is deterministic even when the proxy URL is invalid.
delete @ENV{qw(http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY)};

# HTTP::Tiny returns ARRAY refs for headers repeated on the wire.
my $original_headers = {
    'set-cookie'          => ['SESSION=one; Path=/', 'TOKEN=two; Path=/'],
    'content-type'        => 'application/json',
    'x-request-id'        => 'req-123',
    'ratelimit-remaining' => '2',
};
my $api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    transport => sub {
        return {
            status  => 200,
            headers => $original_headers,
            content => '{"ok":true}',
        };
    },
);
my $response = $api->get('/cookies');
isa_ok $response, 'HTTP::API::Core::Response';
is $response->json->{ok}, 1, 'JSON decodes with repeated Set-Cookie headers';
is_deeply $response->headers->{'set-cookie'},
    ['SESSION=one; Path=/', 'TOKEN=two; Path=/'],
    'both Set-Cookie values survive transport';
ok !defined($response->header('set-cookie')),
    'conflicting repeated values are not arbitrarily chosen by scalar accessor';
is $response->content_type, 'application/json',
    'unrelated single-value Content-Type still works';
is $response->request_id, 'req-123',
    'request ID extraction still works';
is $response->rate_limit->remaining, 2,
    'rate-limit extraction tolerates repeated unrelated headers';

$original_headers->{'set-cookie'}[0] = 'changed by transport';
is $response->headers->{'set-cookie'}[0], 'SESSION=one; Path=/',
    'response isolates repeated values from original transport header arrays';
my $exposed = $response->headers;
$exposed->{'set-cookie'}[0] = 'changed by caller';
is $response->headers->{'set-cookie'}[0], 'SESSION=one; Path=/',
    'headers accessor defensively copies nested arrays';

my $direct = HTTP::API::Core::Response->new(
    status => 200,
    headers => {
        'Set-Cookie' => ['x=1', 'y=2'],
        'X-Request-Id' => ['same', 'same'],
        'Content-Type' => ['application/json', 'text/plain'],
    },
);
is_deeply $direct->headers->{'set-cookie'}, ['x=1', 'y=2'],
    'direct Response constructor retains repeated headers';
is $direct->request_id, 'same',
    'identical repeated values are safe as scalar metadata';
ok !defined($direct->content_type),
    'conflicting repeated Content-Type is not arbitrarily selected';

my $same_case = HTTP::API::Core::Response->new(
    status => 200,
    headers => {
        'Set-Cookie' => ['a=1', 'b=2'],
        'set-cookie' => ['a=1', 'b=2'],
    },
);
is_deeply $same_case->headers->{'set-cookie'}, ['a=1', 'b=2'],
    'case-insensitive matching arrays retain all values';
my $conflicting_case = HTTP::API::Core::Response->new(
    status => 200,
    headers => {
        'Set-Cookie' => ['a=1'],
        'set-cookie' => ['b=2'],
    },
);
ok !defined($conflicting_case->headers->{'set-cookie'}),
    'conflicting case-insensitive arrays remain ambiguous';

my $limits = HTTP::API::Core::RateLimit->from_headers({
    'set-cookie' => ['x=1', 'y=2'],
    'ratelimit-remaining' => ['0', '3'],
    'retry-after' => ['1', '9999'],
    'ratelimit-reset' => '4',
});
ok !defined($limits->remaining),
    'conflicting repeated quota does not select zero';
ok !defined($limits->retry_after),
    'conflicting repeated Retry-After does not select arbitrary delay';
is $limits->wait_seconds(now => 1_000), 4,
    'valid reset is available when Retry-After is ambiguous';

my $error_api = HTTP::API::Core->new(
    base_url => 'https://api.example.test',
    retry => { attempts => 1 },
    transport => sub {
        return {
            status => 429,
            headers => {
                'set-cookie' => ['a=1', 'b=2'],
                'retry-after' => ['1', '10000'],
                'ratelimit-remaining' => ['0', '5'],
            },
        };
    },
);
my $error;
eval { $error_api->get('/limited'); 1 } or $error = $@;
isa_ok $error, 'HTTP::API::Core::Error';
is $error->category, 'http',
    'repeated response headers do not turn valid HTTP errors into transport errors';
ok !defined($error->retry_after),
    'error metadata ignores conflicting repeated Retry-After';
ok !defined($error->rate_limit->remaining),
    'error metadata ignores conflicting repeated quota';
is_deeply $error->headers->{'set-cookie'}, ['a=1', 'b=2'],
    'error exposes full repeated header values through response';

for my $bad ( [{}], ['good', []], {} ) {
    my $bad_api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 1 },
        transport => sub {
            return { status => 200, headers => { 'set-cookie' => $bad } };
        },
    );
    my $caught;
    eval { $bad_api->get('/invalid'); 1 } or $caught = $@;
    isa_ok $caught, 'HTTP::API::Core::Error';
    is $caught->category, 'transport',
        'invalid nested response header uses structured transport error';
}

# Exercise the built-in HTTP::Tiny path without a network connection.
{
    no warnings 'redefine';
    local *HTTP::Tiny::request = sub {
        return {
            status => 200,
            headers => { 'set-cookie' => ['one=1', 'two=2'] },
            content => '{}',
        };
    };
    my $default_api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
    );
    is_deeply $default_api->get('/default')->headers->{'set-cookie'},
        ['one=1', 'two=2'],
        'default HTTP::Tiny transport preserves repeated response headers';
}

done_testing;
