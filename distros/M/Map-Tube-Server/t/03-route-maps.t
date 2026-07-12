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

subtest 'GET /maps' => sub {
    TestMapTubeServer::set_api_response( { content => '["London","NYC"]' } );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/maps');

        is( $res->code, 200, 'GET /maps returns 200 OK' );
        is(
            $res->header('Content-Type'),
            'application/json',
            'GET /maps returns Content-Type: application/json'
        );

        # Body must be a valid JSON array.
        my $decoded = eval { decode_json( $res->content ) };
        ok( !$@ && ref($decoded) eq 'ARRAY', 'GET /maps body is a JSON array' );
        is_deeply(
            $decoded, [ 'London', 'NYC' ],
            'GET /maps returns the expected map list'
        );
    };
};

subtest 'GET /maps invokes available_maps without a map name' => sub {
    TestMapTubeServer::set_api_response( { content => '[]' } );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/maps');
        is( $res->code, 200, '200 OK' );

        my $call = TestMapTubeServer::last_received_call();
        is( $call->{method}, 'available_maps',
            'route called ->available_maps' );
    };
};

subtest 'GET /maps with unsupported path' => sub {
    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->(GET '/');
        isnt( $res->code, 200, 'root path is not handled by /maps route' );
    };
};

done_testing;
