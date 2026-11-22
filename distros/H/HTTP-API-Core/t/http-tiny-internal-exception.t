use strict;
use warnings;
use Test::More;
use HTTP::API::Core;
use HTTP::API::Core::Error;
use HTTP::Tiny;

# These tests make no network requests. Ignore inherited proxy settings so
# HTTP::Tiny construction is deterministic even when the proxy URL is invalid.
delete @ENV{qw(http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY)};

# HTTP::Tiny's pseudo-response is not an HTTP status returned by a server.
{
    no warnings 'redefine';
    local *HTTP::Tiny::request = sub {
        my ($http, $method, $url, $opts) = @_;
        return {
            success => '',
            status  => 599,
            reason  => 'Internal Exception',
            headers => { 'content-type' => 'text/plain' },
            content => 'Could not connect: connection refused',
        };
    };

    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry    => { attempts => 1 },
    );

    my $error;
    eval { $api->get('/users'); 1 } or $error = $@;
    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->category, 'transport',
        'HTTP::Tiny 599 Internal Exception is a transport failure';
    ok $error->retryable, 'synthetic 599 transport error is retryable';
    ok !defined($error->status), 'synthetic status is not exposed as server HTTP status';
    ok !defined($error->response), 'synthetic failure has no HTTP response';
    is $error->method, 'GET', 'transport error retains request method';
    is $error->url, 'https://api.example.test/users',
        'transport error retains request URL';
    like $error->message, qr/Could not connect: connection refused/,
        'internal exception detail is available for diagnostics';
}

# Default HTTP::Tiny retries a transient connection failure for GET.
{
    my $calls = 0;
    no warnings 'redefine';
    local *HTTP::Tiny::request = sub {
        $calls++;
        return {
            status => 200,
            reason => 'OK',
            headers => {},
            content => '{"ok":true}',
        } if $calls == 2;
        return {
            status => 599,
            reason => 'Internal Exception',
            headers => {},
            content => 'transient network failure',
        };
    };
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => {
            attempts => 2,
            base_delay => 0,
            max_delay => 0,
            jitter => 0,
        },
    );
    is $api->get('/users')->status, 200, 'safe GET retries after synthetic transport failure';
    is $calls, 2, 'exactly one retry is made';
}

# Unsafe methods still do not retry on the same transport failure.
{
    my $calls = 0;
    no warnings 'redefine';
    local *HTTP::Tiny::request = sub {
        $calls++;
        return {
            status => 599,
            reason => 'Internal Exception',
            headers => {},
            content => 'connection reset',
        };
    };
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => {
            attempts => 3,
            base_delay => 0,
            max_delay => 0,
            jitter => 0,
        },
    );
    my $error;
    eval { $api->post('/users', json => { name => 'alice' }); 1 } or $error = $@;
    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->category, 'transport', 'POST recognizes synthetic transport failure';
    is $calls, 1, 'POST remains non-retryable by default';
}

# A custom adapter may return a real HTTP 599; its existing semantics stay.
{
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 1 },
        transport => sub {
            return {
                status => 599,
                reason => 'Internal Exception',
                headers => {},
                content => 'remote server response',
            };
        },
    );
    my $error;
    eval { $api->get('/users'); 1 } or $error = $@;
    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->category, 'http', 'custom transport 599 retains HTTP category';
    is $error->status, 599, 'custom transport preserves HTTP 599 status';
    is $error->body, 'remote server response', 'custom transport retains response body';
}

# Do not reclassify a real server response with a different reason.
{
    no warnings 'redefine';
    local *HTTP::Tiny::request = sub {
        return {
            status  => 599,
            reason  => 'Backend Failure',
            headers => {},
            content => 'remote server response',
        };
    };
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 1 },
    );
    my $error;
    eval { $api->get('/users'); 1 } or $error = $@;
    is $error->category, 'http',
        'HTTP::Tiny 599 with another reason remains an HTTP error';
    is $error->status, 599, 'real HTTP status is preserved';
}

done_testing;
