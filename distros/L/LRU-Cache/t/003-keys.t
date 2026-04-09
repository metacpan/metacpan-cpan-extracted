use strict;
use warnings;
use Test::More tests => 8;

use LRU::Cache;

# Test keys() method returns in LRU order
my $cache = LRU::Cache::new(5);

$cache->set('a', 1);
$cache->set('b', 2);
$cache->set('c', 3);

my @keys = $cache->keys;
is_deeply(\@keys, ['c', 'b', 'a'], 'keys in LRU order (most recent first)');

# Access 'a' to promote it
$cache->get('a');
@keys = $cache->keys;
is_deeply(\@keys, ['a', 'c', 'b'], 'keys updated after get');

# Test update existing key
$cache->set('b', 20);
is($cache->get('b'), 20, 'value updated');
@keys = $cache->keys;
is($keys[0], 'b', 'updated key moved to front');

# Test complex values
my $c2 = LRU::Cache::new(10);
$c2->set('hash', { name => 'Bob', age => 30 });
$c2->set('array', [1, 2, 3]);
$c2->set('ref', \42);

my $h = $c2->get('hash');
is_deeply($h, { name => 'Bob', age => 30 }, 'hash value preserved');

my $a = $c2->get('array');
is_deeply($a, [1, 2, 3], 'array value preserved');

my $r = $c2->get('ref');
is($$r, 42, 'scalar ref value preserved');

# Test undef value
$c2->set('undef', undef);
ok($c2->exists('undef'), 'key with undef value exists');
