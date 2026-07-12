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

TestMapTubeServer::install_mock_api( response => { content => '[]' } );

my $app = Map::Tube::Server->to_app;

subtest 'before hook sets Content-Type to application/json on every route' => sub {
    my @paths = (
        '/maps',
        '/stations/london',
        '/stations/london/metropolitan',
        '/shortest-route/london/baker%20street/wembley%20park',
    );

    test_psgi $app, sub {
        my $cb = shift;
        for my $path (@paths) {
            my $res = $cb->(GET $path);
            is(
                $res->header('Content-Type'),
                'application/json',
                "Content-Type for GET $path is application/json"
            );
        }
    };
};

done_testing;
