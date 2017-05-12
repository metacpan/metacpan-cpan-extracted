
# tests for functions documented in memcached_delete.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
        memcached_delete_by_key
    ),
    #   other functions used by the tests
    qw(
        memcached_set_by_key
        memcached_get_by_key
    );

use lib 't/lib';
use libmemcached_test;

my $t1= time();
my $m1= "master-key"; # can't have spaces
my $k1= "$0-test-key-$t1"; # can't have spaces
my $v1= "$0 test value $t1";
my $ret;

my $memc = libmemcached_test_create();

plan tests => 6;

ok $memc;

ok memcached_set_by_key($memc, $m1, $k1, $v1);
ok $ret= memcached_get_by_key($memc, $m1, $k1);
cmp_ok $ret, 'eq', $v1, 'should be equal';

ok memcached_delete_by_key($memc, $m1, $k1);

ok !memcached_get_by_key($memc, $m1, $k1);

