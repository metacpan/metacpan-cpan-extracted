
# tests for functions documented in memcached_set.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
        memcached_prepend_by_key
        memcached_append_by_key
    ),
    #   other functions used by the tests
    qw(
        memcached_set_by_key
        memcached_get_by_key
    );

use lib 't/lib';
use libmemcached_test;

my $pre= 'begin ';
my $end= ' end';
my $m1= 'master-key';
my $k1= 'abc';
my $flags;
my $rc;

my $memc = libmemcached_test_create({ min_version => "1.2.4" });

plan tests => 6;

my $orig = "middle";
ok memcached_set_by_key($memc, $m1, $k1, $orig);

ok memcached_prepend_by_key($memc, $m1, $k1, $pre);

ok memcached_append_by_key($memc, $m1, $k1, $end);

my $ret= memcached_get_by_key($memc, $m1, $k1, $flags=0, $rc=0);
ok $rc, 'memcached_get_by_key rc should be true';
ok defined $ret, 'memcached_get_by_key result should be defined';

my $combined= $pre . $orig . $end;
cmp_ok $ret, 'eq', $combined;

