
# tests for functions documented in memcached_delete.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
        memcached_delete
    ),
    #   other functions used by the tests
    qw(
        memcached_set
        memcached_get
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();

plan tests => 1;

ok $memc;
