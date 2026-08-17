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

done_testing;
