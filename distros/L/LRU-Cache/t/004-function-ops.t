#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 16;
use LRU::Cache qw(import);

# Test that function-style ops are imported
can_ok(__PACKAGE__, 'lru_get');
can_ok(__PACKAGE__, 'lru_set');
can_ok(__PACKAGE__, 'lru_exists');
can_ok(__PACKAGE__, 'lru_peek');
can_ok(__PACKAGE__, 'lru_delete');

my $cache = LRU::Cache::new(100);
isa_ok($cache, 'LRU::Cache');

# Test lru_set
my $ret = lru_set($cache, "foo", 42);
is($ret, 42, 'lru_set returns value');

lru_set($cache, "bar", 99);

# Test lru_get
is(lru_get($cache, "foo"), 42, 'lru_get returns correct value');
is(lru_get($cache, "bar"), 99, 'lru_get returns another value');
is(lru_get($cache, "missing"), undef, 'lru_get returns undef for missing');

# Test lru_exists
ok(lru_exists($cache, "foo"), 'lru_exists returns true for existing');
ok(!lru_exists($cache, "missing"), 'lru_exists returns false for missing');

# Test lru_peek
is(lru_peek($cache, "foo"), 42, 'lru_peek returns value');

# Test lru_delete
my $deleted = lru_delete($cache, "bar");
is($deleted, 99, 'lru_delete returns deleted value');
ok(!lru_exists($cache, "bar"), 'deleted key no longer exists');

# Verify lru_get still works on remaining
is(lru_get($cache, "foo"), 42, 'foo still accessible after delete');
