use strict;
use warnings;
use Test::More;
use Socket qw(AF_INET AF_INET6);

use IO::Socket::HappyEyeballs;

# Test cache operations
IO::Socket::HappyEyeballs->clear_cache;

# Set a cache entry
IO::Socket::HappyEyeballs::_cache_result('example.invalid', 80, AF_INET6);

# Verify it influences sorting
my @addrs = (
  { family => AF_INET6, addr => 'a' },
  { family => AF_INET,  addr => 'b' },
);

my @sorted = IO::Socket::HappyEyeballs::_sort_addresses(\@addrs, 'example.invalid', 80);
is($sorted[0]{family}, AF_INET6, 'IPv6 cached: IPv6 first');

# Now cache IPv4
IO::Socket::HappyEyeballs::_cache_result('example.invalid', 80, AF_INET);
@sorted = IO::Socket::HappyEyeballs::_sort_addresses(\@addrs, 'example.invalid', 80);
is($sorted[0]{family}, AF_INET, 'IPv4 cached: IPv4 first');

# Test clear_cache
IO::Socket::HappyEyeballs->clear_cache;
@sorted = IO::Socket::HappyEyeballs::_sort_addresses(\@addrs, 'example.invalid', 80);
is($sorted[0]{family}, AF_INET6, 'after clear_cache: default IPv6 first');

# Test cache_ttl
my $old_ttl = IO::Socket::HappyEyeballs->cache_ttl;
IO::Socket::HappyEyeballs->cache_ttl(1);
is(IO::Socket::HappyEyeballs->cache_ttl, 1, 'cache_ttl setter works');

IO::Socket::HappyEyeballs::_cache_result('ttl.invalid', 80, AF_INET);
sleep 2;
@sorted = IO::Socket::HappyEyeballs::_sort_addresses(\@addrs, 'ttl.invalid', 80);
is($sorted[0]{family}, AF_INET6, 'expired cache entry is ignored');

# Restore
IO::Socket::HappyEyeballs->cache_ttl($old_ttl);
IO::Socket::HappyEyeballs->clear_cache;

done_testing;
