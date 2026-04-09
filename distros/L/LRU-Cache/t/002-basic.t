use strict;
use warnings;
use Test::More tests => 18;

use LRU::Cache;

# Create cache
my $cache = LRU::Cache::new(3);
isa_ok($cache, 'LRU::Cache', 'new returns LRU::Cache object');
is($cache->capacity, 3, 'capacity is 3');
is($cache->size, 0, 'initial size is 0');

# Set and get
$cache->set('a', 1);
is($cache->get('a'), 1, 'get returns set value');
is($cache->size, 1, 'size is 1 after set');

# Multiple sets
$cache->set('b', 2);
$cache->set('c', 3);
is($cache->size, 3, 'size is 3 after 3 sets');

# Eviction on capacity
$cache->set('d', 4);  # Should evict 'a'
is($cache->size, 3, 'size stays at capacity');
ok(!$cache->exists('a'), 'oldest key was evicted');
ok($cache->exists('d'), 'new key exists');

# Get promotes
$cache->get('b');  # Promote 'b' to front
$cache->set('e', 5);  # Should evict 'c' (now oldest)
ok(!$cache->exists('c'), 'c was evicted after b was promoted');
ok($cache->exists('b'), 'b still exists after promotion');

# Peek does not promote
my $fresh = LRU::Cache::new(2);
$fresh->set('x', 10);
$fresh->set('y', 20);
$fresh->peek('x');  # Should NOT promote x
$fresh->set('z', 30);  # Should evict x (still oldest)
ok(!$fresh->exists('x'), 'peek did not promote');
ok($fresh->exists('y'), 'y still exists');

# Delete
my $val = $fresh->delete('y');
is($val, 20, 'delete returns value');
ok(!$fresh->exists('y'), 'deleted key no longer exists');
is($fresh->size, 1, 'size decreased after delete');

# Clear
$fresh->set('foo', 1);
$fresh->clear;
is($fresh->size, 0, 'size is 0 after clear');
ok(!$fresh->exists('z'), 'keys gone after clear');
