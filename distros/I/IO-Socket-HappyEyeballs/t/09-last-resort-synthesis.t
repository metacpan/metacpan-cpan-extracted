use strict;
use warnings;
use Test::More;
use Socket qw(AF_INET AF_INET6 SOCK_STREAM IPPROTO_TCP
  pack_sockaddr_in pack_sockaddr_in6 inet_pton);

use IO::Socket::HappyEyeballs;

# Test last_resort_delay accessor
{
  my $old = IO::Socket::HappyEyeballs->last_resort_delay;
  is($old, 2, 'default last_resort_delay is 2 seconds');

  IO::Socket::HappyEyeballs->last_resort_delay(3);
  is(IO::Socket::HappyEyeballs->last_resort_delay, 3, 'setter works');

  IO::Socket::HappyEyeballs->last_resort_delay($old);
}

# Test _synthesize_nat64_addr
{
  # Create a fake NAT64 prefix (64:ff9b::/96)
  my $prefix = inet_pton(AF_INET6, '64:ff9b::');
  $prefix = substr($prefix, 0, 12);

  my $ipv4_packed = inet_pton(AF_INET, '192.0.2.1');
  my $ipv4_sockaddr = pack_sockaddr_in(80, $ipv4_packed);

  my $ipv4_addrinfo = {
    family   => AF_INET,
    socktype => SOCK_STREAM,
    protocol => IPPROTO_TCP,
    addr     => $ipv4_sockaddr,
  };

  my $result = IO::Socket::HappyEyeballs::_synthesize_nat64_addr(
    $ipv4_addrinfo, $prefix, 80);

  ok($result, 'synthesis produced a result');
  is($result->{family}, AF_INET6, 'synthesized address is IPv6');
  is($result->{socktype}, SOCK_STREAM, 'socktype preserved');

  # Verify the synthesized address is 64:ff9b::192.0.2.1
  my ($synth_port, $synth_addr) = Socket::unpack_sockaddr_in6($result->{addr});
  is($synth_port, 80, 'port preserved in synthesized address');

  my $expected = inet_pton(AF_INET6, '64:ff9b::c000:201');
  is($synth_addr, $expected, 'synthesized IPv6 matches 64:ff9b::c000:201');
}

# Test _synthesize_nat64_addr rejects non-IPv4 input
{
  my $prefix = substr(inet_pton(AF_INET6, '64:ff9b::'), 0, 12);
  my $ipv6_sockaddr = pack_sockaddr_in6(80, inet_pton(AF_INET6, '::1'));

  my $result = IO::Socket::HappyEyeballs::_synthesize_nat64_addr(
    { family => AF_INET6, addr => $ipv6_sockaddr }, $prefix, 80);
  ok(!$result, 'synthesis rejects non-IPv4 input');
}

# Test _detect_nat64_prefix returns undef on non-NAT64 network
{
  IO::Socket::HappyEyeballs->clear_cache;
  my $prefix = IO::Socket::HappyEyeballs::_detect_nat64_prefix();
  # On a normal dual-stack network, ipv4only.arpa should not return AAAA
  # This test just verifies the function doesn't crash
  ok(1, '_detect_nat64_prefix runs without error');
  if ($prefix) {
    is(length($prefix), 12, 'NAT64 prefix is 12 bytes (96 bits)');
  } else {
    pass('no NAT64 prefix detected (expected on non-NAT64 network)');
  }
}

# Test _last_resort_synthesis with very short delay (unit test)
{
  IO::Socket::HappyEyeballs->last_resort_delay(0);

  my $result = IO::Socket::HappyEyeballs::_last_resort_synthesis(
    'test.invalid', 80, {},
    time(),       # last_attempt_time = now
    time() + 5,   # deadline = 5s from now
  );

  # test.invalid should not resolve, so we get undef
  ok(!$result || !@$result, 'synthesis returns nothing for unresolvable host');

  IO::Socket::HappyEyeballs->last_resort_delay(2);
}

# Test _last_resort_synthesis respects deadline
{
  IO::Socket::HappyEyeballs->last_resort_delay(10);

  my $start = time();
  my $result = IO::Socket::HappyEyeballs::_last_resort_synthesis(
    'localhost', 80, {},
    time(),       # last_attempt_time = now
    time() + 1,   # deadline = only 1 second (less than delay)
  );

  my $elapsed = time() - $start;
  ok($elapsed < 2, 'synthesis respects deadline and returns quickly');

  IO::Socket::HappyEyeballs->last_resort_delay(2);
}

done_testing;
