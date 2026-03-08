use strict;
use warnings;
use Test::More;
use Socket qw(AF_INET AF_INET6);

use_ok('IO::Socket::HappyEyeballs');

# Test _sort_addresses interleaving

# Mock addresses
my @addrs = (
  { family => AF_INET6, addr => 'a' },
  { family => AF_INET6, addr => 'b' },
  { family => AF_INET,  addr => 'c' },
  { family => AF_INET,  addr => 'd' },
);

IO::Socket::HappyEyeballs->clear_cache;

my @sorted = IO::Socket::HappyEyeballs::_sort_addresses(\@addrs, 'test.invalid', 80);
is(scalar @sorted, 4, 'all addresses preserved');
is($sorted[0]{family}, AF_INET6, 'first is IPv6');
is($sorted[1]{family}, AF_INET,  'second is IPv4');
is($sorted[2]{family}, AF_INET6, 'third is IPv6');
is($sorted[3]{family}, AF_INET,  'fourth is IPv4');

# Test with only IPv4
my @ipv4_only = (
  { family => AF_INET, addr => 'a' },
  { family => AF_INET, addr => 'b' },
);

my @sorted2 = IO::Socket::HappyEyeballs::_sort_addresses(\@ipv4_only, 'test.invalid', 80);
is(scalar @sorted2, 2, 'IPv4 only preserved');
is($sorted2[0]{family}, AF_INET, 'first is IPv4');
is($sorted2[1]{family}, AF_INET, 'second is IPv4');

# Test with only IPv6
my @ipv6_only = (
  { family => AF_INET6, addr => 'a' },
  { family => AF_INET6, addr => 'b' },
);

my @sorted3 = IO::Socket::HappyEyeballs::_sort_addresses(\@ipv6_only, 'test.invalid', 80);
is(scalar @sorted3, 2, 'IPv6 only preserved');
is($sorted3[0]{family}, AF_INET6, 'first is IPv6');

# Test cache influence - simulate cached IPv4 preference
IO::Socket::HappyEyeballs::_cache_result('cached.invalid', 80, AF_INET);
my @cached_sorted = IO::Socket::HappyEyeballs::_sort_addresses(\@addrs, 'cached.invalid', 80);
is($cached_sorted[0]{family}, AF_INET,  'cached IPv4 preference: first is IPv4');
is($cached_sorted[1]{family}, AF_INET6, 'cached IPv4 preference: second is IPv6');

IO::Socket::HappyEyeballs->clear_cache;

done_testing;
