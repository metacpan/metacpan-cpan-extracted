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

subtest 'GET /stations/:map returns 200 with JSON stations' => sub {
    TestMapTubeServer::set_api_response(
        { content => '["Baker Street","Wembley Park"]' }
    );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/stations/london');

        is( $res->code, 200, 'GET /stations/london returns 200' );
        is(
            $res->header('Content-Type'),
            'application/json',
            'Content-Type is application/json'
        );

        my $decoded = decode_json( $res->content );
        is_deeply(
            $decoded,
            [ 'Baker Street', 'Wembley Park' ],
            'body decodes to expected stations list'
        );

        my $call = TestMapTubeServer::last_received_call();
        is( $call->{method}, 'map_stations',
            'route called ->map_stations' );
    };
};

subtest 'GET /stations/:map/:line returns 200 with line stations' => sub {
    TestMapTubeServer::set_api_response(
        { content => '["Baker Street","Great Portland Street"]' }
    );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/stations/london/metropolitan');

        is( $res->code, 200, 'GET /stations/london/metropolitan returns 200' );
        is(
            $res->header('Content-Type'),
            'application/json',
            'Content-Type is application/json'
        );

        my $decoded = decode_json( $res->content );
        is_deeply(
            $decoded,
            [ 'Baker Street', 'Great Portland Street' ],
            'body decodes to expected line stations'
        );

        my $call = TestMapTubeServer::last_received_call();
        is( $call->{method}, 'line_stations',
            'route called ->line_stations' );
    };
};

subtest 'GET /stations/:map passes the map name to api' => sub {
    TestMapTubeServer::set_api_response( { content => '[]' } );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/stations/paris');
        is( $res->code, 200, '200 OK for an arbitrary map name' );

        my $call = TestMapTubeServer::last_received_call();
        is( $call->{method}, 'map_stations',
            'map_stations was invoked' );
    };
};

subtest 'GET /stations/:map/:line passes the line name' => sub {
    TestMapTubeServer::set_api_response( { content => '[]' } );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/stations/london/central');
        is( $res->code, 200, '200 OK for an arbitrary line name' );

        my $call = TestMapTubeServer::last_received_call();
        is( $call->{method}, 'line_stations',
            'line_stations was invoked' );
    };
};

done_testing;
