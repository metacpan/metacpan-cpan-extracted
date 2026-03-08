package IO::Socket::HappyEyeballs;
# ABSTRACT: RFC 8305 Happy Eyeballs v2 connection algorithm

use strict;
use warnings;
use Carp;
use Errno qw( EINPROGRESS ECONNREFUSED EISCONN );
use IO::Socket::IP;
use Socket qw(
  getaddrinfo getnameinfo pack_sockaddr_in6 unpack_sockaddr_in6
  AF_INET AF_INET6 AF_UNSPEC
  SOCK_STREAM IPPROTO_TCP
  NI_NUMERICHOST NI_NUMERICSERV
  SOL_SOCKET SO_ERROR
  AI_ADDRCONFIG
  inet_pton inet_ntop
);
use IO::Select;

use parent qw(IO::Socket::IP);

our $VERSION = '0.002';

# Class-level cache: { "host:port" => { family => AF_INET6|AF_INET, expires => time } }
my %_cache;
my $CACHE_TTL = 600; # 10 minutes

# Default connection attempt delay per RFC 8305 §5: 250ms
my $DEFAULT_DELAY = 0.250;

# Last Resort Local Synthesis Delay per RFC 8305 §7.2: 2 seconds
my $LAST_RESORT_DELAY = 2;

my $_override_active;

sub import {
  my ($class, @args) = @_;
  for my $arg (@args) {
    if ($arg eq '-override') {
      $class->_install_override unless $_override_active;
    }
  }
}

sub _install_override {
  my ($class) = @_;
  my $original_new = IO::Socket::IP->can('new');
  my $original_configure = IO::Socket::IP->can('configure');
  no warnings 'redefine';

  # Override configure to skip connect on already-connected sockets.
  # When a subclass (e.g. Net::HTTP) calls configure after Happy Eyeballs
  # has already connected, IO::Socket::IP::configure must not reconnect.
  *IO::Socket::IP::configure = sub {
    my ($self, $cnf) = @_;
    if (delete ${*$self}{io_socket_happyeyeballs_connected}) {
      return $self;
    }
    return $original_configure->($self, $cnf);
  };

  *IO::Socket::IP::new = sub {
    my ($ip_class, %args) = @_;
    # Only intercept TCP connections with a peer
    if (($args{PeerHost} || $args{PeerAddr}) && $args{PeerPort}) {
      my $proto = $args{Proto} || '';
      my $type  = $args{Type}  || 0;
      if (!$proto || $proto eq 'tcp' || $type == SOCK_STREAM || !$type) {
        my $sock = IO::Socket::HappyEyeballs->_happy_connect(\%args);
        if ($sock) {
          # For subclasses (e.g. Net::HTTP): rebless and let their
          # configure run for protocol-specific setup, while our
          # IO::Socket::IP::configure override skips reconnecting.
          if ($ip_class ne 'IO::Socket::IP'
              && $ip_class ne 'IO::Socket::HappyEyeballs'
              && $ip_class->isa('IO::Socket::IP')) {
            bless $sock, $ip_class;
            ${*$sock}{io_socket_happyeyeballs_connected} = 1;
            $sock->configure(\%args) if $sock->can('configure');
          }
          return $sock;
        }
        return;
      }
    }
    return $original_new->($ip_class, %args);
  };
  $_override_active = 1;
}

sub _happy_connect {
  my ($class, $args) = @_;
  # Use our Happy Eyeballs algorithm
  my $peer_host = $args->{PeerHost} || $args->{PeerAddr};
  my $peer_port = $args->{PeerPort};

  my $delay   = delete $args->{ConnectionAttemptDelay} // $DEFAULT_DELAY;
  my $timeout = $args->{Timeout} // 30;

  my @addresses = _resolve($peer_host, $peer_port, $args);
  unless (@addresses) {
    $@ = "Cannot resolve host '$peer_host': no addresses found";
    return;
  }

  @addresses = _sort_addresses(\@addresses, $peer_host, $peer_port);

  my $sock = _attempt_connections(\@addresses, $delay, $timeout, $args,
    $peer_host, $peer_port);

  if ($sock) {
    _cache_result($peer_host, $peer_port, $sock->sockdomain);
    return $sock;
  }

  $@ = "Cannot connect to $peer_host:$peer_port: all attempts failed";
  return;
}

sub new {
  my ($class, %args) = @_;

  my $peer_host = $args{PeerHost} || $args{PeerAddr}
    or croak "PeerHost or PeerAddr is required";
  my $peer_port = $args{PeerPort}
    or croak "PeerPort is required";

  my $delay   = delete $args{ConnectionAttemptDelay} // $DEFAULT_DELAY;
  my $timeout = $args{Timeout} // 30;

  # Resolve addresses
  my @addresses = _resolve($peer_host, $peer_port, \%args);
  unless (@addresses) {
    $@ = "Cannot resolve host '$peer_host': no addresses found";
    return;
  }

  # Sort with interleaving per RFC 8305 §4
  @addresses = _sort_addresses(\@addresses, $peer_host, $peer_port);

  # Attempt connections with Happy Eyeballs algorithm
  my $sock = _attempt_connections(\@addresses, $delay, $timeout, \%args,
    $peer_host, $peer_port);

  if ($sock) {
    _cache_result($peer_host, $peer_port, $sock->sockdomain);
    return $sock;
  }

  $@ = "Cannot connect to $peer_host:$peer_port: all attempts failed";
  return;
}

sub _resolve {
  my ($host, $port, $args) = @_;

  # Respect GetAddrInfoFlags from IO::Socket::IP compatibility,
  # default to AI_ADDRCONFIG per RFC 8305 recommendation.
  my $flags = exists $args->{GetAddrInfoFlags}
    ? $args->{GetAddrInfoFlags}
    : AI_ADDRCONFIG;

  my %hints = (
    socktype => SOCK_STREAM,
    protocol => IPPROTO_TCP,
    family   => AF_UNSPEC,
    ($flags ? (flags => $flags) : ()),
  );

  my ($err, @results) = getaddrinfo($host, $port, \%hints);

  # If AI_ADDRCONFIG returned nothing (e.g. loopback-only interfaces),
  # retry without it to avoid filtering out valid addresses.
  if (($err || !@results) && $flags) {
    delete $hints{flags};
    ($err, @results) = getaddrinfo($host, $port, \%hints);
  }

  if ($err) {
    $@ = "getaddrinfo failed: $err";
    return;
  }

  return @results;
}

sub _sort_addresses {
  my ($addresses, $host, $port) = @_;

  # Check cache for preferred family
  my $cache_key = "$host:$port";
  my $preferred_family;
  if (my $cached = $_cache{$cache_key}) {
    if ($cached->{expires} > time()) {
      $preferred_family = $cached->{family};
    } else {
      delete $_cache{$cache_key};
    }
  }

  # Separate by address family
  my (@ipv6, @ipv4);
  for my $addr (@$addresses) {
    if ($addr->{family} == AF_INET6) {
      push @ipv6, $addr;
    } else {
      push @ipv4, $addr;
    }
  }

  # Interleave: preferred family first, then alternate
  # Per RFC 8305 §4
  my @sorted;
  my ($primary, $secondary);
  if ($preferred_family && $preferred_family == AF_INET) {
    $primary   = \@ipv4;
    $secondary = \@ipv6;
  } else {
    $primary   = @ipv6 ? \@ipv6 : \@ipv4;
    $secondary = @ipv6 ? \@ipv4 : \@ipv6;
  }

  while (@$primary || @$secondary) {
    push @sorted, shift @$primary   if @$primary;
    push @sorted, shift @$secondary if @$secondary;
  }

  return @sorted;
}

sub _attempt_connections {
  my ($addresses, $delay, $timeout, $args, $host, $port) = @_;

  my @pending;     # [ socket, addrinfo ] pairs
  my $select = IO::Select->new;
  my $deadline = time() + $timeout;
  my $next_attempt_time = 0; # start first attempt immediately

  my $addr_idx = 0;
  my $last_attempt_time;
  my $last_resort_done = 0;

  while ($addr_idx < @$addresses || @pending) {
    my $now = time();
    last if $now >= $deadline;

    # RFC 8305 §7.2: Last Resort Local Synthesis
    # When all initial addresses are exhausted and all pending have failed,
    # wait until $LAST_RESORT_DELAY seconds after last attempt, then try
    # A-record-only resolution with NAT64 synthesis.
    if (!$last_resort_done && $addr_idx >= @$addresses && !@pending
        && $last_attempt_time) {
      my $synth_addresses = _last_resort_synthesis(
        $host, $port, $args, $last_attempt_time, $deadline);
      if ($synth_addresses && @$synth_addresses) {
        push @$addresses, @$synth_addresses;
        $last_resort_done = 1;
        next;  # re-enter loop to process new addresses
      }
      $last_resort_done = 1;
    }

    # Start a new connection attempt if it's time
    if ($addr_idx < @$addresses && $now >= $next_attempt_time) {
      my $addr = $addresses->[$addr_idx++];
      my $sock = _start_connect($addr, $args);

      if ($sock) {
        # Check if already connected (localhost etc.)
        if ($sock->connected) {
          _cleanup_pending(\@pending);
          _restore_blocking($sock, $args);
          return $sock;
        }
        push @pending, [ $sock, $addr ];
        $select->add($sock);
      }

      $last_attempt_time = time();
      $next_attempt_time = $last_attempt_time + $delay;
    }

    next unless @pending;

    # Calculate how long to wait
    my $wait_time;
    if ($addr_idx < @$addresses) {
      # Wait until either a connection succeeds or it's time for the next attempt
      $wait_time = $next_attempt_time - time();
      $wait_time = 0 if $wait_time < 0;
    } else {
      # No more addresses to try, wait for remaining connections
      $wait_time = $deadline - time();
      $wait_time = 0 if $wait_time < 0;
    }

    # select() for writable (connected) sockets
    my @ready = IO::Select->select(undef, $select, undef, $wait_time);

    if (@ready && $ready[1]) {
     for my $sock (@{$ready[1]}) {
      # Check if the connection actually succeeded
      my $err = $sock->sockopt(SO_ERROR);
      if ($err == 0) {
        # Success! Clean up all other pending sockets
        my @others = grep { $_->[0] != $sock } @pending;
        _cleanup_pending(\@others);
        _restore_blocking($sock, $args);

        return $sock;
      } else {
        # This connection failed, remove it
        $select->remove($sock);
        $sock->close;
        @pending = grep { $_->[0] != $sock } @pending;
      }
     }
    }
  }

  # All failed
  _cleanup_pending(\@pending);
  return;
}

sub _start_connect {
  my ($addr, $args) = @_;

  my $sock = IO::Socket::IP->new;
  $sock->socket($addr->{family}, $addr->{socktype}, $addr->{protocol})
    or return;

  $sock->blocking(0);

  my $rv = CORE::connect($sock, $addr->{addr});
  if ($rv) {
    # Connected immediately
    return $sock;
  }
  if ($! == EINPROGRESS) {
    # Connection in progress — this is the normal non-blocking case
    return $sock;
  }

  # Immediate failure
  $sock->close;
  return;
}

sub _restore_blocking {
  my ($sock, $args) = @_;
  if (exists $args->{Blocking} && !$args->{Blocking}) {
    $sock->blocking(0);
  } else {
    $sock->blocking(1);
  }
}

sub _cleanup_pending {
  my ($pending) = @_;
  for my $p (@$pending) {
    $p->[0]->close if $p->[0];
  }
}

# RFC 8305 §7.2: Last Resort Local Synthesis
# After all AAAA-based attempts fail, wait for the synthesis delay,
# then query A records and synthesize IPv6 via NAT64 if available.
sub _last_resort_synthesis {
  my ($host, $port, $args, $last_attempt_time, $deadline) = @_;

  return unless defined $host && defined $port;

  # Wait until $LAST_RESORT_DELAY after last attempt fired
  my $synthesis_time = $last_attempt_time + $LAST_RESORT_DELAY;
  my $now = time();
  if ($now < $synthesis_time) {
    my $wait = $synthesis_time - $now;
    return if $now + $wait > $deadline;
    select(undef, undef, undef, $wait);
  }

  # Query A records only (IPv4)
  my ($err, @ipv4_results) = getaddrinfo($host, $port, {
    socktype => SOCK_STREAM,
    protocol => IPPROTO_TCP,
    family   => AF_INET,
  });
  return unless @ipv4_results;

  # Detect NAT64 prefix via RFC 7050 (ipv4only.arpa)
  my $nat64_prefix = _detect_nat64_prefix();

  if ($nat64_prefix) {
    # Synthesize IPv6 addresses from IPv4 using NAT64 prefix
    my @synthesized;
    for my $r (@ipv4_results) {
      my $synth = _synthesize_nat64_addr($r, $nat64_prefix, $port);
      push @synthesized, $synth if $synth;
    }
    return \@synthesized if @synthesized;
  }

  # No NAT64: return IPv4 addresses directly as fallback
  return \@ipv4_results;
}

# RFC 7050: Discovery of the IPv6 Prefix Used for IPv6 Address Synthesis
# Resolve ipv4only.arpa AAAA — if we get results, NAT64 is present
# and the prefix can be extracted from the response.
my $_nat64_prefix_cache;
my $_nat64_prefix_expires = 0;

sub _detect_nat64_prefix {
  my $now = time();
  if ($now < $_nat64_prefix_expires) {
    return $_nat64_prefix_cache;
  }

  # The well-known IPv4 addresses for ipv4only.arpa are
  # 192.0.0.170 and 192.0.0.171. If AAAA resolution returns
  # results, the NAT64 prefix is the first 96 bits.
  my ($err, @results) = getaddrinfo('ipv4only.arpa', '443', {
    socktype => SOCK_STREAM,
    family   => AF_INET6,
  });

  if (!$err && @results) {
    my ($synth_port, $synth_addr) = unpack_sockaddr_in6($results[0]{addr});
    # The well-known address 192.0.0.170 = 0xC0000AA in the last 32 bits
    # Extract the first 12 bytes as the NAT64 prefix
    my $prefix = substr($synth_addr, 0, 12);
    $_nat64_prefix_cache = $prefix;
    $_nat64_prefix_expires = $now + 600; # cache for 10 minutes
    return $prefix;
  }

  $_nat64_prefix_cache = undef;
  $_nat64_prefix_expires = $now + 60; # negative cache for 1 minute
  return;
}

# Synthesize an IPv6 address by combining NAT64 prefix with IPv4 address
sub _synthesize_nat64_addr {
  my ($ipv4_addrinfo, $nat64_prefix, $port) = @_;

  # Extract the IPv4 address from the sockaddr
  my $family = $ipv4_addrinfo->{family};
  return unless $family == AF_INET;

  my ($ipv4_port, $ipv4_packed) = Socket::unpack_sockaddr_in($ipv4_addrinfo->{addr});

  # Build synthesized IPv6 address: 96-bit prefix + 32-bit IPv4
  my $synth_ipv6 = $nat64_prefix . $ipv4_packed;
  my $synth_sockaddr = pack_sockaddr_in6($ipv4_port, $synth_ipv6);

  return {
    family   => AF_INET6,
    socktype => SOCK_STREAM,
    protocol => IPPROTO_TCP,
    addr     => $synth_sockaddr,
  };
}

sub _cache_result {
  my ($host, $port, $family) = @_;
  $_cache{"$host:$port"} = {
    family  => $family,
    expires => time() + $CACHE_TTL,
  };
}

sub clear_cache {
  %_cache = ();
  $_nat64_prefix_cache = undef;
  $_nat64_prefix_expires = 0;
}

sub last_resort_delay {
  my ($class, $new_delay) = @_;
  if (defined $new_delay) {
    $LAST_RESORT_DELAY = $new_delay;
  }
  return $LAST_RESORT_DELAY;
}

sub connection_attempt_delay {
  my ($class, $new_delay) = @_;
  if (defined $new_delay) {
    $DEFAULT_DELAY = $new_delay;
  }
  return $DEFAULT_DELAY;
}

sub cache_ttl {
  my ($class, $new_ttl) = @_;
  if (defined $new_ttl) {
    $CACHE_TTL = $new_ttl;
  }
  return $CACHE_TTL;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Socket::HappyEyeballs - RFC 8305 Happy Eyeballs v2 connection algorithm

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # Direct usage:
  use IO::Socket::HappyEyeballs;

  my $sock = IO::Socket::HappyEyeballs->new(
    PeerHost => 'www.example.com',
    PeerPort => 80,
  );
  die "Cannot connect: $@" unless $sock;
  print $sock "GET / HTTP/1.0\r\nHost: www.example.com\r\n\r\n";

  # Global override — makes ALL IO::Socket::IP connections use Happy Eyeballs:
  use IO::Socket::HappyEyeballs -override;

  # Now any code using IO::Socket::IP gets Happy Eyeballs automatically,
  # including LWP::UserAgent, HTTP::Tiny, Net::Async::HTTP, etc.
  use HTTP::Tiny;
  my $response = HTTP::Tiny->new->get('http://www.example.com');

=head1 DESCRIPTION

This module implements the B<Happy Eyeballs> algorithm for establishing TCP
connections to dual-stack hosts (hosts reachable via both IPv4 and IPv6).

This module was created because David Leadbeater (DGL) needed it.

=head2 The problem

As the internet transitions from IPv4 to IPv6, many hosts are reachable via
both protocols ("dual-stack"). A naive client that tries IPv6 first will
experience long timeouts (typically 30-75 seconds) when IPv6 connectivity is
broken — even though IPv4 would work instantly. This is a common situation:
a host publishes AAAA records but the user's network path to that host over
IPv6 is broken somewhere along the way.

=head2 The solution: Happy Eyeballs

The Happy Eyeballs algorithm (originally specified in
L<RFC 6555|https://tools.ietf.org/html/rfc6555>, updated in
L<RFC 8305|https://tools.ietf.org/html/rfc8305>) solves this by racing
connection attempts in parallel:

=over

=item 1. B<Resolve> the hostname to all available addresses (both AAAA and A records)

=item 2. B<Sort> the addresses with interleaving — IPv6 first, then alternate between families (e.g. IPv6, IPv4, IPv6, IPv4, ...)

=item 3. B<Start> connecting to the first address (typically IPv6)

=item 4. B<Wait> 250ms — if not connected yet, start connecting to the next address (typically IPv4) I<in parallel>

=item 5. B<Continue> starting new attempts every 250ms while previous ones are still pending

=item 6. B<Return> the first socket that successfully connects, close all others

=item 7. B<Cache> the winning address family so future connections try it first

=back

The 250ms delay is called the B<Connection Attempt Delay>. It is short enough
to avoid noticeable lag, but long enough to give the preferred address family
(IPv6) a fair chance to connect first.

=head2 RFC compliance

This module implements B<RFC 8305> ("Happy Eyeballs Version 2: Better
Connectivity Using Concurrency"), which supersedes the original B<RFC 6555>
("Happy Eyeballs: Success with Dual-Stack Hosts").

Key RFC 8305 features implemented:

=over

=item * B<Address interleaving> (Section 4) — alternating address families

=item * B<Connection attempt delay> (Section 5) — 250ms default, configurable

=item * B<First-wins> connection racing — parallel non-blocking connects via C<select()>

=item * B<Address family caching> (Section 5.2) — successful family is remembered

=item * B<Last Resort Local Synthesis> (Section 7.2) — handles broken AAAA records via NAT64 synthesis fallback

=back

=head2 Using the C<-override> import flag

The most powerful way to use this module is with the C<-override> flag:

  use IO::Socket::HappyEyeballs -override;

This transparently replaces C<< IO::Socket::IP->new() >> with the Happy
Eyeballs algorithm for all outgoing TCP connections in the entire process.
Any library that uses L<IO::Socket::IP> internally — including L<HTTP::Tiny>,
L<LWP::UserAgent>, L<Net::Async::HTTP>, L<IO::Async>, and many others —
will automatically benefit.

Only outgoing TCP connections (those with C<PeerHost>/C<PeerAddr> and
C<PeerPort>) are intercepted. Listening sockets, UDP sockets, and Unix domain
sockets are passed through to the original C<IO::Socket::IP> unchanged.

=head2 ConnectionAttemptDelay

Time in seconds to wait before starting the next connection attempt.
Defaults to 0.250 (250ms) per RFC 8305 Section 5. Can be passed to C<new()>.

=head2 Timeout

Overall connection timeout in seconds. Defaults to 30.

=head2 new

  my $sock = IO::Socket::HappyEyeballs->new(%args);

Creates a new socket connection using the Happy Eyeballs v2 algorithm
(RFC 8305). Accepts the same arguments as L<IO::Socket::IP> plus:

=over

=item ConnectionAttemptDelay

Delay in seconds between connection attempts (default: 0.250).

=back

Returns the connected socket on success, or C<undef> on failure with C<$@>
set to an error message.

=head2 clear_cache

  IO::Socket::HappyEyeballs->clear_cache;

Clears the internal address family preference cache.

=head2 connection_attempt_delay

  IO::Socket::HappyEyeballs->connection_attempt_delay(0.300);
  my $delay = IO::Socket::HappyEyeballs->connection_attempt_delay;

Get/set the default connection attempt delay in seconds. The default is 0.250
(250ms) as recommended by RFC 8305 Section 5.

=head2 cache_ttl

  IO::Socket::HappyEyeballs->cache_ttl(300);
  my $ttl = IO::Socket::HappyEyeballs->cache_ttl;

Get/set the address family cache TTL in seconds. The default is 600
(10 minutes). When a successful connection is made, the winning address
family (IPv4 or IPv6) is cached for this duration. Subsequent connections
to the same host:port will try the cached family first.

=head2 last_resort_delay

  IO::Socket::HappyEyeballs->last_resort_delay(3);
  my $delay = IO::Socket::HappyEyeballs->last_resort_delay;

Get/set the Last Resort Local Synthesis Delay in seconds per RFC 8305
Section 7.2. The default is 2 seconds. This is the time to wait after the
last connection attempt before falling back to A-record-only resolution
with NAT64 address synthesis. This handles the case of hostnames with
broken AAAA records on IPv6-only networks with NAT64/DNS64.

=head1 SEE ALSO

=over

=item * L<RFC 8305 — Happy Eyeballs Version 2: Better Connectivity Using Concurrency|https://tools.ietf.org/html/rfc8305>

=item * L<RFC 6555 — Happy Eyeballs: Success with Dual-Stack Hosts|https://tools.ietf.org/html/rfc6555>

=item * L<IO::Socket::IP> — the parent class

=item * L<IO::Socket::INET> — basic IPv4 socket class (no dual-stack support)

=item * L<IO::Socket::Happpy::EyeBalls|https://github.com/masanorih/p5-IO-Socket-Happpy-EyeBalls> — earlier Happy Eyeballs implementation that this module builds upon (not uploaded to CPAN)

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-io-socket-happyeyeballs/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
