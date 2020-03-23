#!/usr/bin/env perl

use warnings;
use strict;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::Deep;
use Test::Exception;
use Test::More;

use Future;
use GraphQL::Client::http;

HTTP::AnyUA->register_backend(MockUA => '+MockUA');

my $URL = 'http://localhost:4000/graphql';

subtest 'attributes' => sub {
    my $http = GraphQL::Client::http->new;

    is($http->method, 'POST', 'default method is POST');
    is($http->url, undef, 'default url is undefined');

    $http = GraphQL::Client::http->new(method => 'HEAD', url => $URL);

    is($http->method, 'HEAD', 'method getter returns correctly');
    is($http->url, $URL, 'url getter returns correctly');
};

subtest 'bad arguments to execute' => sub {
    my $http = GraphQL::Client::http->new(ua => 'MockUA');
    my $mock = $http->any_ua->backend;

    throws_ok {
        $http->execute('blah');
    } qr/^Usage:/, 'first argument must be a hashref';

    throws_ok {
        $http->execute({});
    } qr/^Request must have a query/, 'request must have a query';

    throws_ok {
        $http->execute({query => '{hello}'});
    } qr/^URL must be provided/, 'request must have a URL';
};

subtest 'POST request' => sub {
    my $http = GraphQL::Client::http->new(ua => 'MockUA', url => $URL);
    my $mock = $http->any_ua->backend;

    my $resp = $http->execute({
        query   => '{hello}',
    });
    my $req = ($mock->requests)[-1];

    is($req->[0], 'POST', 'method is POST');
    is($req->[2]{content}, '{"query":"{hello}"}', 'encoded body as JSON');
    is($req->[2]{headers}{'content-type'}, 'application/json;charset=UTF-8', 'set content-type to json');
};

subtest 'GET request' => sub {
    my $http = GraphQL::Client::http->new(ua => 'MockUA', url => $URL);
    my $mock = $http->any_ua->backend;

    $http->execute({
        query   => '{hello}',
    }, {
        method  => 'GET',
    });
    my $req = ($mock->requests)[-1];

    is($req->[0], 'GET', 'method is GET');
    is($req->[1], "$URL?query=%7Bhello%7D", 'encoded query in params');
    is($req->[2]{content}, undef, 'no content');

    $http->execute({
        query   => '{hello}',
    }, {
        method  => 'GET',
        url     => "$URL?foo=bar",
    });
    $req = ($mock->requests)[-1];

    is($req->[1], "$URL?foo=bar&query=%7Bhello%7D", 'encoded query in params with existing param');
};

subtest 'plain response' => sub {
    my $http = GraphQL::Client::http->new(ua => 'MockUA', url => $URL);
    my $mock = $http->any_ua->backend;

    $mock->response({
        content => '{"data":{"foo":"bar"}}',
        reason  => 'OK',
        status  => 200,
        success => 1,
    });
    my $r = $http->execute({query => '{hello}'});
    my $expected = {
        response => {
            data => {foo => 'bar'},
        },
        details => {
            http_response => $mock->response,
        },
    };
    is_deeply($r, $expected, 'success response') or diag explain $r;

    $mock->response({
        content => '{"data":{"foo":"bar"},"errors":[{"message":"uh oh"}]}',
        reason  => 'OK',
        status  => 200,
        success => 1,
    });
    $r = $http->execute({query => '{hello}'});
    $expected = {
        response => {
            data    => {foo => 'bar'},
            errors  => [{message => 'uh oh'}],
        },
        details => {
            http_response => $mock->response,
        },
    };
    is_deeply($r, $expected, 'response with graphql errors') or diag explain $r;

    $mock->response({
        content => 'The agent failed',
        reason  => 'Internal Exception',
        status  => 599,
        success => '',
    });
    my $resp = $http->execute({query => '{hello}'});
    $expected = {
        error => 'HTTP transport returned 599 (Internal Exception): The agent failed',
        response => undef,
        details => {
            http_response => $mock->response,
        },
    };
    is_deeply($resp, $expected, 'response with http error') or diag explain $resp;

    $mock->response({
        content => 'not json',
        reason  => 'OK',
        status  => 200,
        success => 1,
    });
    $r = $http->execute({query => '{hello}'});
    $expected = {
        error => re('^HTTP transport failed to decode response:'),
        response => undef,
        details => {
            http_response => $mock->response,
        },
    };
    cmp_deeply($r, $expected, 'response with invalid response') or diag explain $r;
};

subtest 'future response' => sub {
    my $http = GraphQL::Client::http->new(ua => 'MockUA', url => $URL);
    my $mock = $http->any_ua->backend;

    $mock->response(Future->done({
        content => '{"data":{"foo":"bar"}}',
        reason  => 'OK',
        status  => 200,
        success => 1,
    }));
    my $f = $http->execute({query => '{hello}'});
    my $expected = {
        response => {
            data => {foo => 'bar'},
        },
        details => {
            http_response => $mock->response->get,
        },
    };
    is_deeply($f->get, $expected, 'success response') or diag explain $f->get;

    $mock->response(Future->done({
        content => '{"data":{"foo":"bar"},"errors":[{"message":"uh oh"}]}',
        reason  => 'OK',
        status  => 200,
        success => 1,
    }));
    $f = $http->execute({query => '{hello}'});
    $expected = {
        response => {
            data => {foo => 'bar'},
            errors  => [{message => 'uh oh'}],
        },
        details => {
            http_response => $mock->response->get,
        },
    };
    is_deeply($f->get, $expected, 'response with graphql errors') or diag explain $f->get;

    $mock->response(Future->fail({
        content => 'The agent failed',
        reason  => 'Internal Exception',
        status  => 599,
        success => '',
    }));
    $expected = {
        error => 'HTTP transport returned 599 (Internal Exception): The agent failed',
        response => undef,
        details => {
            http_response => ($mock->response->failure)[0],
        },
    };
    $f = $http->execute({query => '{hello}'});
    is_deeply($f->get, $expected, 'response with http error') or diag explain $f->get;
};

done_testing;
