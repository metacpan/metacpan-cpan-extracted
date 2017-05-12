#!perl

use strict;
use warnings;

use Etcd3;
use Test::More;
use Test::Exception;

my ($host, $port);

if ( $ENV{ETCD_TEST_HOST} and $ENV{ETCD_TEST_PORT}) {
    $host = $ENV{ETCD_TEST_HOST};
    $port = $ENV{ETCD_TEST_PORT};
    plan tests => 3;
}
else {
    plan skip_all => "Please set environment variable ETCD_TEST_HOST and ETCD_TEST_PORT.";
}

my $etcd = Etcd3->connect( $host, { port => $port } );

my $key;

# put key/value
lives_ok(
    sub {
        $key = $etcd->put( { key => 'foo1', value => 'bar' } )->request
    },
    "add a new key value pair"
);

# get range
lives_ok(
    sub {
        $key = $etcd->range( { key => 'foo1' } )->get_value
    },
    "get key value"
);

# delete range
lives_ok(
    sub {
        $key = $etcd->delete_range( { key => 'foo1' } )->request
    },
    "delete key value"
);

1;
