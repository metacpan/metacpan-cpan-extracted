
# tests for functions documented in memcached_servers.pod

use strict;
use warnings;

use Test::More tests => 10;

BEGIN {
use_ok( 'Memcached::libmemcached',
#   functions explicitly tested by this file
qw(
    memcached_server_count
    memcached_server_add
    memcached_server_add_unix_socket
),
#   other functions used by the tests
qw(
    memcached_create
    memcached_free
));
}

my $memc;

ok $memc = memcached_create(undef);

is memcached_server_count($memc), 0, 'should have 0 elements';

ok memcached_server_add($memc, "bar", 1234);
is memcached_server_count($memc), 1, 'should have 1 element';

ok memcached_server_add($memc, "foo");
is memcached_server_count($memc), 2, 'should have 2 elements';

ok memcached_server_add_unix_socket($memc, "/tmp/none-such-libmemcached-socket");
is memcached_server_count($memc), 3, 'should have 3 elements';

# XXX memcached_free
#
ok 1;
