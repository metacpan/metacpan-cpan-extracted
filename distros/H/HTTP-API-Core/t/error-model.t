use strict;
use warnings;
use Test::More;

use HTTP::API::Core;
use HTTP::API::Core::Error;

my %stable = map { $_ => 1 } qw(encode decode transport http hook);

{
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 1 },
        transport => sub {
            return {
                status => 422,
                reason => 'Unprocessable Entity',
                headers => {
                    'Content-Type' => 'application/problem+json',
                    'X-Request-Id' => 'req-error-1',
                },
                content => '{"error":"bad input"}',
            };
        },
    );

    my $error;
    eval { $api->post('/users', json => {name => 'x'}); 1 } or $error = $@;

    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->category, 'http', 'HTTP failure uses stable http category';
    ok $stable{$error->category}, 'category belongs to documented stable set';
    is $error->status, 422, 'status is available';
    is $error->body, '{"error":"bad input"}', 'body exposes response content';
    is $error->text, '{"error":"bad input"}', 'text mirrors response text';
    is $error->header('content-type'), 'application/problem+json', 'header accessor delegates to response';
    is $error->request_id, 'req-error-1', 'request ID is preserved';
    is $error->json->{error}, 'bad input', 'json decodes associated response';

    my $headers = $error->headers;
    $headers->{'content-type'} = 'changed';
    is $error->header('content-type'), 'application/problem+json', 'headers is a defensive copy';
    isa_ok $error->response, 'HTTP::API::Core::Response';
    like "$error", qr/HTTP 422/, 'stringification remains human-readable';
}

{
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 1 },
        transport => sub { die "network down\n" },
    );

    my $error;
    eval { $api->get('/users'); 1 } or $error = $@;

    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->category, 'transport', 'transport failure uses stable category';
    ok $stable{$error->category}, 'transport category belongs to stable set';
    is $error->response, undef, 'transport error has no response';
    is $error->body, undef, 'body is undef without response';
    is $error->text, undef, 'text is undef without response';
    is $error->header('x-test'), undef, 'header is undef without response';
    is_deeply $error->headers, {}, 'headers returns empty hash without response';
    is $error->json, undef, 'json is undef without response';
}

{
    my $response = HTTP::API::Core::Response->new(
        status => 200,
        reason => 'OK',
        headers => {'Content-Type' => 'application/json'},
        content => 'not json',
        method => 'GET',
        url => 'https://api.example.test/bad-json',
    );

    my $error;
    eval { $response->json; 1 } or $error = $@;

    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->category, 'decode', 'invalid explicit JSON uses stable decode category';
    ok $stable{$error->category}, 'decode category belongs to stable set';
    is $error->response, $response, 'decode error retains response';
    is $error->body, 'not json', 'decode error exposes raw body';
}

{
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        transport => sub {
            return { status => 200, reason => 'OK', headers => {}, content => '{}' };
        },
    );

    my $error;
    eval {
        my $cycle = {};
        $cycle->{self} = $cycle;
        $api->post('/encode', json => $cycle);
        1;
    } or $error = $@;

    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->category, 'encode', 'encoding failure uses stable encode category';
    ok $stable{$error->category}, 'encode category belongs to stable set';
}

{
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        hooks => {
            before_request => sub { die "hook failed\n" },
        },
        transport => sub {
            die "transport should not run";
        },
    );

    my $error;
    eval { $api->get('/hook'); 1 } or $error = $@;

    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->category, 'hook', 'hook failure uses stable hook category';
    ok $stable{$error->category}, 'hook category belongs to stable set';
    ok !$error->retryable, 'hook errors are non-retryable';
}

done_testing;
