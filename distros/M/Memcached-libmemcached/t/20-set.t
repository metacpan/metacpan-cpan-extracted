
# tests for functions documented in memcached_set.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
        memcached_set
    ),
    #   other functions used by the tests
    qw(
        memcached_server_add
        memcached_create
        memcached_free
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();

plan tests => 1;

ok memcached_set($memc, 'abc', "this is a test");
