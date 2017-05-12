
# tests for functions documented in memcached_get.pod
# (except for memcached_fetch_result)

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
        memcached_callback_set
        memcached_callback_get
        MEMCACHED_CALLBACK_PREFIX_KEY
        MEMCACHED_BEHAVIOR_HASH_WITH_PREFIX_KEY
    ),
    #   other functions used by the tests
    qw(
        memcached_set
        memcached_get
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();
my $expire = 5;

plan tests => 13;

ok $memc->memcached_set("f1:a", 4201, $expire);
ok $memc->memcached_set("f2:a", 4202, $expire);
is $memc->memcached_get("f1:a"), 4201;
is $memc->memcached_get("f2:a"), 4202;

ok $memc->memcached_callback_set(MEMCACHED_CALLBACK_PREFIX_KEY, "f1:");
is $memc->memcached_callback_get(MEMCACHED_CALLBACK_PREFIX_KEY), "f1:";
is $memc->memcached_get("a"), 4201;

ok $memc->memcached_callback_set(MEMCACHED_CALLBACK_PREFIX_KEY, "f2:");
is $memc->memcached_callback_get(MEMCACHED_CALLBACK_PREFIX_KEY), "f2:";
is $memc->memcached_get("a"), 4202;

TODO: {
    local $TODO = "MEMCACHED_CALLBACK_PREFIX_KEY should allow empty prefix";
    ok $memc->memcached_callback_set(MEMCACHED_CALLBACK_PREFIX_KEY, "");
    is $memc->memcached_get("f1:a"), 4201;
    is $memc->memcached_get("f2:a"), 4202;
}
