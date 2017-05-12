
# tests for functions documented in memcached_verbosity.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
    ),
    #   other functions used by the tests
    qw(
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();

plan tests => 1;

ok $memc;
