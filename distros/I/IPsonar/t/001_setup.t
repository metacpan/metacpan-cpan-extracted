#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Builder;
use Data::Dumper;
use 5.10.0;

BEGIN { use_ok('IPsonar') }

# Requires TEST_RSN and TEST_REPORT environment variables to be set
# this and subsequent tests will use these to figure out which server
# and report to run against.

my $rsn;
my $rsn_address = $ENV{TEST_RSN};
my $test_report = $ENV{TEST_REPORT};

SKIP: {
    if ( !( $rsn_address && $test_report ) ) {
        skip( "TEST_RSN or TEST_REPORT not set.", 2 );
    }

    $rsn = IPsonar->new( $rsn_address, 'admin', 'admin' );
    my $results;
    eval { $results = $rsn->query( 'management.systemInformation', {} ); };
    is( $results->{apiVersion}, '5.0', 'Connect to RSN and verify apiVersion' );

    $rsn = IPsonar->new( $rsn_address, 'admin', 'admin' );
    eval { $results = $rsn->query( 'invalid.ipsonar.call', {} ); };
    like( $@, qr/RuntimeException/, 'Check error handling for bad call' );
}

$rsn = IPsonar->new( '127.0.0.1', 'admin', 'admin' );
eval {
    my $results = $rsn->query(
        'config.reports',
        {
            'q.pageSize' => 100,
        }
    );
};
ok( $@, "query croaks on invalid RSN" );

