# tests for functions documented in memcached_create.pod

use strict;
use warnings;

# XXX memcached_clone needs more testing for non-undef args

use Test::More tests => 5;

BEGIN {
use_ok( 'Memcached::libmemcached',
#   functions explicitly tested by this file
qw(
    memcached_create
    memcached_free
    memcached_clone
),
#   other functions used by the tests
qw(
));
}

my ($memc, $memc2);

ok $memc = memcached_create();
memcached_free($memc);

ok $memc = memcached_create();

ok $memc2 = memcached_clone(undef, undef);

memcached_free($memc2);

memcached_free($memc);

print "duplicate memcached_free\n";
memcached_free($memc);

ok 1;
