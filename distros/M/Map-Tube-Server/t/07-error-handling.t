#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use lib 't/lib';
use TestMapTubeServer;

BEGIN { use_ok('Map::Tube::Server') || print "Bail out!\n"; }

TestMapTubeServer::install_mock_api();

my $app = Map::Tube::Server->to_app;

subtest 'GET /maps: BAD_REQUEST (400) is propagated' => sub {
    plan tests => 3;

    TestMapTubeServer::set_api_response(
        { error_code => 400, error_message => 'Missing map name.' }
    );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/maps');

        is( $res->code, 400, 'status is 400' );
        is(
            $res->header('Content-Type'),
            'application/json',
            'Content-Type is still JSON for errors'
        );
        is( $res->content, 'Missing map name.',
            'body matches the error message' );
    };
};

subtest 'GET /maps: TOO_MANY_REQUESTS (429) is propagated' => sub {
    plan tests => 2;

    TestMapTubeServer::set_api_response(
        { error_code => 429, error_message => 'Reached request limit.' }
    );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/maps');
        is( $res->code, 429, 'status is 429' );
        is( $res->content, 'Reached request limit.',
            'body matches the error message' );
    };
};

subtest 'GET /maps: MEMCACHE_SERVER_ERROR (430) is propagated' => sub {
    plan tests => 2;

    TestMapTubeServer::set_api_response(
        { error_code => 430, error_message => 'Memcache server is unreachable.' }
    );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/maps');
        is( $res->code, 430, 'status is 430' );
        is( $res->content, 'Memcache server is unreachable.',
            'body matches the error message' );
    };
};

subtest 'GET /stations/:map: error from map_stations is propagated' => sub {
    plan tests => 2;

    TestMapTubeServer::set_api_response(
        { error_code => 400, error_message => 'Map not installed' }
    );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/stations/london');
        is( $res->code, 400, 'status is 400' );
        is( $res->content, 'Map not installed',
            'body matches the error message' );
    };
};

subtest 'GET /stations/:map/:line: error from line_stations is propagated' => sub {
    plan tests => 2;

    TestMapTubeServer::set_api_response(
        { error_code => 400, error_message => 'Received invalid line name.' }
    );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/stations/london/not-a-line');
        is( $res->code, 400, 'status is 400' );
        is( $res->content, 'Received invalid line name.',
            'body matches the error message' );
    };
};

subtest 'GET /shortest-route/:map/:start/:end: error from shortest_route is propagated' => sub {
    plan tests => 2;

    TestMapTubeServer::set_api_response(
        { error_code => 400, error_message => 'Received invalid start station name.' }
    );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(
            GET '/shortest-route/london/no-such-station/wembley%20park' );
        is( $res->code, 400, 'status is 400' );
        is( $res->content, 'Received invalid start station name.',
            'body matches the error message' );
    };
};

subtest 'success response still works after an error' => sub {
    plan tests => 2;

    TestMapTubeServer::set_api_response( { content => '["London"]' } );
    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/maps');
        is( $res->code, 200, 'status is 200 after switching back to success' );
        is( $res->content, '["London"]', 'body matches the success payload' );
    };
};

done_testing;
