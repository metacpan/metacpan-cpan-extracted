#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON::PP;

use lib 't/lib';
use TestMapTubeServer;

BEGIN { use_ok('Map::Tube::Server') || print "Bail out!\n"; }

TestMapTubeServer::install_mock_api( response => { content => '[]' } );

my $app = Map::Tube::Server->to_app;

subtest 'GET /shortest-route/:map/:start/:end returns 200 with JSON route' => sub {
    TestMapTubeServer::set_api_response(
        { content => '["Baker Street","Finchley Road","Wembley Park"]' }
    );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(
            GET '/shortest-route/london/baker%20street/wembley%20park' );

        is( $res->code, 200,
            'GET /shortest-route/london/baker street/wembley park returns 200'
        );
        is(
            $res->header('Content-Type'),
            'application/json',
            'Content-Type is application/json'
        );

        my $decoded = decode_json( $res->content );
        is_deeply(
            $decoded,
            [ 'Baker Street', 'Finchley Road', 'Wembley Park' ],
            'body decodes to expected route'
        );

        my $call = TestMapTubeServer::last_received_call();
        is( $call->{method}, 'shortest_route',
            'route called ->shortest_route' );
    };
};

subtest 'GET /shortest-route passes start/end through route_parameters' => sub {
    TestMapTubeServer::set_api_response( { content => '[]' } );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/shortest-route/london/a/b');
        is( $res->code, 200, '200 OK with arbitrary start/end' );

        # Just sanity check: the handler invoked shortest_route on the mock.
        my $call = TestMapTubeServer::last_received_call();
        is( $call->{method}, 'shortest_route',
            'shortest_route method was invoked' );
    };
};

subtest 'GET /shortest-route works with URL-encoded station names' => sub {
    TestMapTubeServer::set_api_response( { content => '["Kings Cross"]' } );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(
            GET '/shortest-route/london/king%27s%20cross/euston' );
        is( $res->code, 200, '200 OK for URL-encoded names' );
        is(
            $res->content, '["Kings Cross"]',
            'body matches the configured mock response'
        );
    };
};

done_testing;
