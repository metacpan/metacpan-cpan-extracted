use strict;
use warnings;
use Test::More;

use HTTP::API::Core::Response;

sub response {
    my (%args) = @_;
    return HTTP::API::Core::Response->new(
        status  => $args{status} // 200,
        reason  => 'OK',
        headers => $args{headers} || {},
        content => exists($args{content}) ? $args{content} : '',
        method  => 'GET',
        url     => 'https://api.example.test/items',
    );
}

{
    my $res = response(content => 'hello');
    is $res->content, 'hello', 'content returns raw body';
    is $res->text, 'hello', 'text aliases raw body';
    ok $res->has_content, 'has_content true for non-empty body';
}

{
    my $res = response(content => '');
    ok !$res->has_content, 'has_content false for zero-length body';
    is $res->json, undef, 'empty body decodes as undef';
}

{
    my $res = response(content => " \n\t ");
    ok $res->has_content, 'whitespace body still has raw content';
    is $res->json, undef, 'whitespace-only body decodes as undef';
}

{
    my $res = response(
        headers => { 'Content-Type' => 'Application/JSON; charset=utf-8' },
        content => '{"ok":true}',
    );
    is $res->content_type, 'application/json', 'content_type strips parameters and normalizes case';
    ok $res->is_json, 'application/json recognized';
    is $res->json->{ok}, 1, 'json decodes JSON body';
}

{
    my $res = response(
        headers => { 'Content-Type' => 'application/problem+json; charset=UTF-8' },
        content => '{"title":"bad"}',
    );
    ok $res->is_json, '+json structured suffix recognized';
    is $res->json->{title}, 'bad', '+json content decodes normally';
}

{
    my $res = response(
        headers => { 'Content-Type' => 'text/plain' },
        content => '{"still":"json"}',
    );
    ok !$res->is_json, 'text/plain is not identified as JSON';
    is $res->json->{still}, 'json', 'explicit json call does not depend on Content-Type';
}

{
    my $res = response(content => '{"x":1}');
    is $res->content_type, undef, 'missing Content-Type returns undef';
    ok !$res->is_json, 'missing Content-Type is not identified as JSON';
    is $res->json->{x}, 1, 'JSON can still be explicitly decoded without Content-Type';
}

{
    my $res = response(content => 'not json');
    my $error;
    eval { $res->json; 1 } or $error = $@;
    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->category, 'decode', 'invalid JSON preserves structured decode error';
    is $error->response, $res, 'decode error references response';
}

{
    my $res = response(headers => { 'X-Test' => 'original' });
    my $headers = $res->headers;
    $headers->{'x-test'} = 'changed';
    is $res->header('X-Test'), 'original', 'headers returns a defensive copy';
}


# HTTP status validation and success classification at each boundary.
for my $case ([100, 0], [199, 0], [200, 1], [299, 1], [300, 0], [599, 0]) {
    my ($status, $success) = @$case;
    my $res = response(status => $status);
    is $res->status, $status, "status $status retained";
    is $res->is_success ? 1 : 0, $success, "status $status success classification";
    is $res->url, 'https://api.example.test/items', 'response retains request URL';
}

for my $case (
    (map { [ [status => $_], qr/response status must be a valid HTTP status/ ] }
        (undef, [], '20x', 99, '099', 600)),
    [ [status => 200, headers => []], qr/response headers must be a hash reference/ ],
    [ [status => 200, headers => { 'X-Test' => {} }], qr/response header values must be scalars/ ],
    [ [status => 200, headers => { 'X-Test' => [undef, {}] }], qr/response header values must be scalars/ ],
    (map { [ [status => 200, $_ => []], qr/response \Q$_\E must be a scalar or undef/ ] }
        qw(reason content method url elapsed)),
) {
    my ($args, $pattern) = @$case;
    my ($error, @warnings);
    {
        local $SIG{__WARN__} = sub { push @warnings, @_ };
        eval { HTTP::API::Core::Response->new(@$args); 1 } or $error = $@;
    }
    like $error, $pattern, 'malformed response constructor input rejected';
    is_deeply \@warnings, [], 'malformed response input rejected without coercion warnings';
}

for my $pair (
    [ '0', ['0'] ],
    [ ['0'], ['0', '0'] ],
    [ [undef, '0'], ['0', '0'] ],
    [ [undef, undef], [undef, undef] ],
    [ undef, undef ],
) {
    my $res = response(headers => {
        'X-Request-Id' => $pair->[0],
        'x-request-id' => $pair->[1],
        'X-Correlation-Id' => 'fallback',
    });
    is $res->header('x-request-id'), undef, 'ambiguous or absent duplicate has no scalar value';
    is $res->request_id, 'fallback', 'request ID uses unambiguous fallback';
}

for my $value ([], [undef, undef], [undef, '0'], ['0', undef]) {
    my $res = response(headers => {
        'X-Test' => $value,
        'Content-Type' => $value,
    });
    is_deeply $res->headers->{'x-test'}, $value, 'raw repeated header remains intact';
    is $res->header('x-test'), undef, 'repeated header with no agreed scalar is unknown';
    is $res->content_type, undef, 'ambiguous or absent media type is unknown';
}

{
    my $res = response(headers => {
        'Content-Type' => '',
        'X-Request-Id' => '',
        'Request-Id' => '0',
    });
    is $res->content_type, undef, 'empty media type is absent';
    is $res->request_id, '0', 'empty request ID falls back to defined zero string';
    for my $name (undef, []) {
        my $error;
        eval { $res->header($name); 1 } or $error = $@;
        like $error, qr/response header name must be a defined scalar/,
            'invalid header lookup name rejected';
    }
}

done_testing;
