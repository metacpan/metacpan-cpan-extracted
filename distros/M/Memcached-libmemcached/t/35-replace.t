
# tests for functions documented in memcached_set.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
        memcached_replace
    ),
    #   other functions used by the tests
    qw(
        memcached_set
        memcached_get
        memcached_errstr
    );

use lib 't/lib';
use libmemcached_test;

my $k1= "replace-".time();
my $orig= 'original content';
my $repl= 'replaced stuff';
my $flags;
my $rc;

my $memc = libmemcached_test_create({ min_version => "1.2.4" });

plan tests => 6;

ok !memcached_replace($memc, $k1, $repl),
    'should fail on non-existing key';

ok memcached_set($memc, $k1, $orig);

ok memcached_replace($memc, $k1, $repl);

my $ret= memcached_get($memc, $k1, $flags=0, $rc=0);
ok $rc, 'memcached_get should work';
ok defined $ret, 'memcached_get result should be defined';

cmp_ok $ret, 'eq', $repl, 'should return replaced value';

