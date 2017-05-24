#!perl

use strict;
use warnings;
use Etcd3;
use Test::More;
use Test::Exception;
use Data::Dumper;
my ($host, $port);

if ( $ENV{ETCD_TEST_HOST} and $ENV{ETCD_TEST_PORT}) {
    $host = $ENV{ETCD_TEST_HOST};
    $port = $ENV{ETCD_TEST_PORT};
    plan tests => 8;
}
else {
    plan skip_all => "Please set environment variable ETCD_TEST_HOST and ETCD_TEST_PORT.";
}

my ($watch,$key);
my $etcd = Etcd3->new( { host => $host, port => $port } );

our @events;
# create watch with callback and store events
lives_ok(
    sub {
        $watch = $etcd->watch( { key => 'foo'}, sub {
            my ($result) =  @_;
            push @events, $result;
            #print STDERR Dumper(undef, $result);
        })->create;
    },
    "watch create"
);

lives_ok(
    sub {
        $key = $etcd->put( { key => 'foo', value => 'bar' } );
    },
    "kv put"
);

#print STDERR Dumper($key);
cmp_ok( $key->{response}{success}, '==', 1, "kv put success" );

# get range
lives_ok(
    sub {
        $key = $etcd->range( { key => 'foo' } )
    },
    "kv range"
);

cmp_ok( $key->{response}{success}, '==', 1, "kv range success" );
#print STDERR Dumper($key);

cmp_ok( scalar @events, '==', 2, "number of async events stored. (create_watch, create key)" );
#print STDERR 'events ' . Dumper(@events);

# delete range
lives_ok(
    sub {
        $key = $etcd->range( { key => 'foo' } )->delete
    },
    "kv range_delete"
);

cmp_ok( $key->{response}{success}, '==', 1, "kv delete success" );

1;
