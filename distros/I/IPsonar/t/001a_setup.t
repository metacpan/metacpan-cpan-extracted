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

$rsn = IPsonar->_new_with_file('t/test1_2.data');

my $results;
eval { $results = $rsn->query( 'management.systemInformation', {} ); };
is( $results->{apiVersion}, '5.0', 'Connect to RSN and verify apiVersion' );

$rsn = IPsonar->_new_with_file('t/test1_2.data');
eval { $results = $rsn->query( 'invalid.ipsonar.call', {} ); };
like( $@, qr/RuntimeException/, 'Check error handling for bad call' );

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

