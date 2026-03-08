# IO::Socket::HappyEyeballs

**RFC 8305 Happy Eyeballs v2 for Perl** — fast, reliable dual-stack TCP connections

## The Problem

When a hostname has both IPv6 (AAAA) and IPv4 (A) DNS records, a client must
decide which to try first. If it picks IPv6 and that path is broken (common
during the ongoing IPv4-to-IPv6 transition), the connection hangs for 30-75
seconds before falling back to IPv4 — even though IPv4 would have connected
instantly.

This makes applications feel slow and broken on networks with partial IPv6
connectivity.

## The Solution

The **Happy Eyeballs** algorithm (RFC 6555, updated by **RFC 8305**) solves
this by racing connection attempts:

1. Resolve the hostname to all addresses (AAAA + A records)
2. Sort with **interleaving** — IPv6 first, then alternate: IPv6, IPv4, IPv6, IPv4, ...
3. Start connecting to the first address (usually IPv6)
4. Wait **250ms** — if not connected, start the next address (usually IPv4) *in parallel*
5. **First one to connect wins**, all others are closed
6. **Cache** the winning address family for future connections

The 250ms delay ("Connection Attempt Delay") gives IPv6 a fair head start
while keeping total connection time fast when IPv6 is broken.

## Installation

```bash
cpanm IO::Socket::HappyEyeballs
```

Or with Dist::Zilla from source:

```bash
dzil install
```

## Usage

### Direct usage

```perl
use IO::Socket::HappyEyeballs;

my $sock = IO::Socket::HappyEyeballs->new(
    PeerHost => 'www.example.com',
    PeerPort => 443,
    Timeout  => 10,
) or die "Cannot connect: $@";
```

### Global override (recommended)

```perl
use IO::Socket::HappyEyeballs -override;
```

This single line makes **every** `IO::Socket::IP->new()` call in the entire
process use Happy Eyeballs — including calls inside libraries like:

- [HTTP::Tiny](https://metacpan.org/pod/HTTP::Tiny)
- [LWP::UserAgent](https://metacpan.org/pod/LWP::UserAgent)
- [Net::Async::HTTP](https://metacpan.org/pod/Net::Async::HTTP)
- [IO::Async](https://metacpan.org/pod/IO::Async)
- Any module that uses `IO::Socket::IP` internally

Only outgoing TCP connections are intercepted. Listening sockets, UDP, and
Unix domain sockets pass through to `IO::Socket::IP` unchanged.

### Configuration

```perl
# Custom connection attempt delay (default: 250ms per RFC 8305)
my $sock = IO::Socket::HappyEyeballs->new(
    PeerHost               => 'www.example.com',
    PeerPort               => 80,
    ConnectionAttemptDelay  => 0.100,   # 100ms
);

# Change the global default delay
IO::Socket::HappyEyeballs->connection_attempt_delay(0.300);  # 300ms

# Change cache TTL (default: 600s = 10 minutes)
IO::Socket::HappyEyeballs->cache_ttl(300);  # 5 minutes

# Change Last Resort Local Synthesis Delay (default: 2s per RFC 8305 §7.2)
IO::Socket::HappyEyeballs->last_resort_delay(3);

# Clear the address family cache
IO::Socket::HappyEyeballs->clear_cache;
```

## How it works internally

```
DNS:  www.example.com → [2001:db8::1, 2001:db8::2, 93.184.216.34, 93.184.216.35]
Sort: [2001:db8::1, 93.184.216.34, 2001:db8::2, 93.184.216.35]  (interleaved)

t=0ms:   connect(2001:db8::1)    → EINPROGRESS
t=250ms: connect(93.184.216.34)  → EINPROGRESS  (IPv6 hasn't connected yet)
t=255ms: 93.184.216.34 connected → return socket, close IPv6 attempt
```

Total time: **255ms** instead of 30+ seconds with naive sequential approach.

## RFCs

| RFC | Title | Status |
|-----|-------|--------|
| [RFC 8305](https://tools.ietf.org/html/rfc8305) | Happy Eyeballs Version 2: Better Connectivity Using Concurrency | **Implemented** |
| [RFC 6555](https://tools.ietf.org/html/rfc6555) | Happy Eyeballs: Success with Dual-Stack Hosts | Superseded by RFC 8305 |
| [RFC 6724](https://tools.ietf.org/html/rfc6724) | Default Address Selection for IPv6 | Used by `getaddrinfo()` |

### RFC 8305 features implemented

- **Section 4** — Address sorting with interleaving between address families
- **Section 5** — Connection Attempt Delay (250ms default)
- **Section 5** — Parallel non-blocking connection racing via `select()`
- **Section 5.2** — Caching of successful address family
- **Section 7.2** — Last Resort Local Synthesis for broken AAAA records (NAT64 via RFC 7050)
- `AI_ADDRCONFIG` for initial resolution, dropped in Last Resort fallback path

### Not yet implemented

- **Section 3** — Parallel A/AAAA DNS queries with separate resolution delay
  (currently relies on `getaddrinfo()` which handles this internally on most systems)
- **Section 3** — SVCB/HTTPS DNS record support

## Dependencies

- [IO::Socket::IP](https://metacpan.org/pod/IO::Socket::IP) (core since Perl 5.20)
- [Socket](https://metacpan.org/pod/Socket) (core)
- [IO::Select](https://metacpan.org/pod/IO::Select) (core)

No non-core dependencies required.

## Testing

```bash
# Unit tests (no network required)
prove -l t/

# Live dual-stack test (connects to a real host)
TEST_HAPPYEYEBALLS_LIVE=1 prove -lv t/80-live-dual-stack.t

# Custom host for live test
TEST_HAPPYEYEBALLS_LIVE=1 TEST_HAPPYEYEBALLS_HOST=example.com prove -lv t/80-live-dual-stack.t
```

## See Also

- [IO::Socket::IP](https://metacpan.org/pod/IO::Socket::IP) — parent class, handles dual-stack but sequentially
- [Net::Happy::Eyeballs](https://metacpan.org/pod/Net::Happy::Eyeballs) — older attempt (never released)
- [IO::Socket::Happpy::EyeBalls](https://github.com/masanorih/p5-IO-Socket-Happpy-EyeBalls) — earlier implementation that this module builds upon (not uploaded to CPAN)

## Acknowledgements

This module was created because David Leadbeater (DGL) needed it.

## Author

Torsten Raudssus <torsten@raudss.us>

## License

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
