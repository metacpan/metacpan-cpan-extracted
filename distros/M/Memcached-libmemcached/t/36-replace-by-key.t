
# tests for functions documented in memcached_set.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
        memcached_replace_by_key
    ),
    #   other functions used by the tests
    qw(
        memcached_set_by_key
        memcached_get_by_key
        memcached_errstr
    );

use lib 't/lib';
use libmemcached_test;

my $m1= "master-key";
my $k1= "replace-".libmemcached_test_key();
my $orig= 'original content';
my $repl= 'replaced stuff';
my $flags;
my $rc;

my $memc = libmemcached_test_create({ min_version => "1.2.4" });

plan tests => 6;

ok !memcached_replace_by_key($memc, $m1, $k1, $repl),
    'should fail on non-existing key';

ok memcached_set_by_key($memc, $m1, $k1, $orig);

ok memcached_replace_by_key($memc, $m1, $k1, $repl);

my $ret= memcached_get_by_key($memc, $m1, $k1, $flags=0, $rc=0);
ok $rc, 'memcached_get_by_key rc should be true';
ok defined $ret, 'memcached_get_by_key result should be defined';
cmp_ok $ret, 'eq', $repl, 'should return replaced value';

# XXX I don't think "should fail on non-existing master key" is right
# when there's only one server
#ok !memcached_replace_by_key($memc, 'bogus-master-key', $k1, $repl),
#    'should fail on non-existing master key';

