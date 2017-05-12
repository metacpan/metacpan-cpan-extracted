
# tests for functions documented in memcached_set.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
        memcached_prepend
        memcached_append
    ),
    #   other functions used by the tests
    qw(
        memcached_set
        memcached_get
    );

use lib 't/lib';
use libmemcached_test;

my $pre= 'begin ';
my $end= ' end';
my $k1= 'abc';
my $flags;
my $rc;

my $memc = libmemcached_test_create({ min_version => "1.2.4" });

plan tests => 6;

my $orig = "middle";
ok memcached_set($memc, $k1, $orig);

ok memcached_prepend($memc, $k1, $pre);

ok memcached_append($memc, $k1, $end);

my $ret= memcached_get($memc, $k1, $flags=0, $rc=0);
ok $rc, 'memcached_get rc should be true';
ok defined $ret, 'memcached_get result should be defined';

my $combined= $pre . $orig . $end;
cmp_ok $ret, 'eq', $combined;

