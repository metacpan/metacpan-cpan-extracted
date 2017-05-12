# tests for functions documented in memcached_create.pod

use strict;
use warnings;

use Test::More tests => 8;

BEGIN {
use_ok( 'Memcached::libmemcached',
#   functions explicitly tested by this file
qw(
),
#   other functions used by the tests
qw(
    memcached_server_add
));
}

my ($memc);

ok $memc = Memcached::libmemcached->new();
is ref $memc, 'Memcached::libmemcached';

ok memcached_server_add($memc, "localhost", 11211);
ok memcached_server_add($memc, "localhost", 11212);
ok $memc->get_server_for_key("test3") eq "localhost:11211", "get_server_for_key test3 == localhost:11211";
ok $memc->get_server_for_key("test") eq "localhost:11212", "get_server_for_key test == localhost:11212";

undef $memc;

ok 1;
