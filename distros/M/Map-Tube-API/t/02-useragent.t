#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use lib 't/lib';

use MockUA;
use HTTP::Response;
use Test::More;
use Map::Tube::API::UserAgent;

{
    my $agent = Map::Tube::API::UserAgent->new;
    isa_ok($agent->ua, 'LWP::UserAgent', 'default ua attribute');
}

{
    my $ok_response = HTTP::Response->new(200, 'OK');
    $ok_response->content('{"result":"fine"}');

    my $mock  = MockUA->new($ok_response);
    my $agent = Map::Tube::API::UserAgent->new(ua => $mock);

    my $response = $agent->get('http://example.test/some/path');
    is($response->decoded_content, '{"result":"fine"}', 'get() returns the response on success');

    is($mock->request_count, 1, 'get() issued exactly one request');
    is($mock->last_request->method, 'GET', 'get() issues a GET request');
    is($mock->last_request->uri, 'http://example.test/some/path', 'get() requests the exact URL given');
}

{
    my $fail_response = HTTP::Response->new(404, 'Not Found');
    $fail_response->content('station not found');

    my $mock  = MockUA->new($fail_response);
    my $agent = Map::Tube::API::UserAgent->new(ua => $mock);

    eval { $agent->get('http://example.test/missing') };
    isa_ok($@, 'Map::Tube::API::Exception', 'get() on a failed response');
    is($@->code,    404,                  'exception carries the HTTP status code');
    is($@->message, 'station not found',  'exception carries the response content as message');
}

{
    my $ok_response = HTTP::Response->new(201, 'Created');
    $ok_response->content('{"created":true}');

    my $mock  = MockUA->new($ok_response);
    my $agent = Map::Tube::API::UserAgent->new(ua => $mock);

    my $response = $agent->post('http://example.test/create', { name => 'foo' });
    is($response->decoded_content, '{"created":true}', 'post() returns the response on success');
    is($mock->last_request->method, 'POST', 'post() issues a POST request');
}

{
    my $fail_response = HTTP::Response->new(500, 'Internal Server Error');
    $fail_response->content('boom');

    my $mock  = MockUA->new($fail_response);
    my $agent = Map::Tube::API::UserAgent->new(ua => $mock);

    eval { $agent->post('http://example.test/create', { name => 'foo' }) };
    isa_ok($@, 'Map::Tube::API::Exception', 'post() on a failed response');
    is($@->code, 500, 'exception carries the HTTP status code for post() failures too');
}

done_testing;
