
# tests for functions documented in memcached_set.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
        memcached_set
        memcached_get
    ),
    #   other functions used by the tests
    qw(
        memcached_server_add
        memcached_create
        memcached_behavior_set
        memcached_free
        memcached_errstr
    ),
    #   binary protocol constant 
    qw(
        MEMCACHED_BEHAVIOR_BINARY_PROTOCOL
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create({ min_version => "1.4.0" });

plan tests => 5;

ok memcached_behavior_set($memc, MEMCACHED_BEHAVIOR_BINARY_PROTOCOL, 1);

my $val = 'this is a test';
ok memcached_set($memc, 'abc', $val);

is memcached_errstr($memc), 'SUCCESS';

my ($flags, $rc);
is memcached_get($memc, 'abc', $flags=0, $rc=0), $val;

ok $rc;

