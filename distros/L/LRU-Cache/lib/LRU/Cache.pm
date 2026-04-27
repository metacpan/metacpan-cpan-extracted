package LRU::Cache;
use strict;
use warnings;
our $VERSION = '0.05';
require XSLoader;
XSLoader::load('LRU::Cache', $VERSION);
1;

__END__

=head1 NAME

LRU::Cache - LRU cache with O(1) operations

=head1 SYNOPSIS

	use LRU::Cache;

	# Create cache with max 1000 entries
	my $cache = LRU::Cache::new(1000);

	# Store values - O(1)
	$cache->set('key1', $value);
	$cache->set('user:123', { name => 'Bob', age => 30 });

	# Retrieve values - O(1), promotes to front
	my $val = $cache->get('key1');

	# Check existence without promoting - O(1)
	if ($cache->exists('key1')) { ... }

	# Peek without promoting - O(1)
	my $val = $cache->peek('key1');

	# Delete entry - O(1)
	$cache->delete('key1');

	# Cache info
	my $size = $cache->size;      # Current entries
	my $cap = $cache->capacity;   # Max entries

	# Clear all entries
	$cache->clear;

	# Get all keys (most recent first)
	my @keys = $cache->keys;

=head2 The function-style API you should use

	use LRU::Cache qw(import);

	my $cache = LRU::Cache::new(1000);

	# Function-style ops eliminate method dispatch overhead
	# ~2x faster than method calls
	lru_set($cache, 'key', $value);    # 40M+ ops/sec
	my $v = lru_get($cache, 'key');    # 62M+ ops/sec
	lru_exists($cache, 'key');         # 60M+ ops/sec
	lru_peek($cache, 'key');           # 60M+ ops/sec
	lru_delete($cache, 'key');         # 60M+ ops/sec

=head1 DESCRIPTION

C<LRU::Cache> provides a fast Least Recently Used cache implemented in C.
All operations are O(1) using a hash table for lookups and a doubly
linked list for ordering.

When the cache reaches capacity, the least recently used entry is
automatically evicted on the next C<set>.

=head2 Performance

=over 4

=item * B<get/set>: O(1) - hash lookup + list splice

=item * B<exists/peek>: O(1) - hash lookup only

=item * B<delete>: O(1) - hash delete + list remove

=back

=head1 METHODS

=head2 LRU::Cache::new($capacity)

Create a new LRU cache with the given maximum capacity.

=head2 $cache->set($key, $value)

Store a value. If key exists, updates value and promotes to front.
If at capacity, evicts least recently used entry first.

=head2 $cache->get($key)

Retrieve a value and promote to front. Returns undef if not found.

=head2 $cache->peek($key)

Retrieve a value without promoting. Returns undef if not found.

=head2 $cache->exists($key)

Check if key exists. Does not promote.

=head2 $cache->delete($key)

Remove an entry. Returns the deleted value or undef.

=head2 $cache->size

Returns the current number of entries.

=head2 $cache->capacity

Returns the maximum capacity.

=head2 $cache->clear

Remove all entries.

=head2 $cache->keys

Returns all keys in order (most recent first).

=head2 $cache->oldest

	my ($key, $value) = $cache->oldest;

Returns the key and value of the least recently used entry (the one
that would be evicted next if the cache is full). Returns an empty
list if the cache is empty.

=head2 $cache->newest

	my ($key, $value) = $cache->newest;

Returns the key and value of the most recently used entry.
Returns an empty list if the cache is empty.

=head1 FUNCTION-STYLE API

For maximum performance, import function-style ops:

	use LRU::Cache qw(import);

This exports the following functions into your namespace:

=head2 lru_set($cache, $key, $value)

Set a key/value pair. Returns the value.
Approximately 70% faster than C<< $cache->set(...) >>.

=head2 lru_get($cache, $key)

Get a value, promoting to front. Returns undef if not found.
Approximately 2x faster than C<< $cache->get(...) >>.

=head2 lru_exists($cache, $key)

Check if key exists. Does not promote.
Approximately 2x faster than C<< $cache->exists(...) >>.

=head2 lru_peek($cache, $key)

Get a value without promoting. Returns undef if not found.
Approximately 2x faster than C<< $cache->peek(...) >>.

=head2 lru_delete($cache, $key)

Delete a key. Returns the deleted value or undef.
Approximately 2x faster than C<< $cache->delete(...) >>.

=head2 lru_oldest($cache)

	my ($key, $value) = lru_oldest($cache);

Returns the key and value of the least recently used entry.
Returns an empty list if the cache is empty.

=head2 lru_newest($cache)

	my ($key, $value) = lru_newest($cache);

Returns the key and value of the most recently used entry.
Returns an empty list if the cache is empty.

=head1 BENCHMARK

	=== set (existing key) ===
	                Rate        PP XS method   XS func
	PP         1715893/s        --      -92%      -96%
	XS method 21445932/s     1150%        --      -52%
	XS func   45124820/s     2530%      110%        --

	=== get (hit) ===
	                Rate        PP XS method   XS func
	PP         5271976/s        --      -71%      -84%
	XS method 18302304/s      247%        --      -45%
	XS func   33017565/s      526%       80%        --

	=== get (miss) ===
	                Rate        PP XS method   XS func
	PP         8133594/s        --      -63%      -83%
	XS method 22125453/s      172%        --      -53%
	XS func   46998887/s      478%      112%        --

	=== exists (hit) ===
	                Rate        PP XS method   XS func
	PP         7080776/s        --      -64%      -82%
	XS method 19521882/s      176%        --      -50%
	XS func   38745035/s      447%       98%        --

	=== peek ===
	                Rate        PP XS method   XS func
	PP         6410022/s        --      -62%      -80%
	XS method 16842291/s      163%        --      -48%
	XS func   32437007/s      406%       93%        --

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1; # End of LRU::Cache
