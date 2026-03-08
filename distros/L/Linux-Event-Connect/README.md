# Linux::Event::Connect

[![CI](https://github.com/haxmeister/perl-linux-event-connect/actions/workflows/ci.yml/badge.svg)](https://github.com/haxmeister/perl-linux-event-connect/actions/workflows/ci.yml)

Nonblocking outbound socket connect primitive for the **Linux::Event** ecosystem.

## Install

```sh
cpanm Linux::Event::Connect
```

## Quick start

```perl
use v5.36;
use Linux::Event;
use Linux::Event::Connect;

my $loop = Linux::Event->new;

Linux::Event::Connect->new(
  loop => $loop,
  host => '127.0.0.1',
  port => 1234,
  timeout_s => 5,

  on_connect => sub ($req, $fh, $data) {
    # connected nonblocking socket
    close $fh;
    $loop->stop;
  },

  on_error => sub ($req, $errno, $data) {
    local $! = $errno;
    warn "connect failed: $errno ($!)\n";
    $loop->stop;
  },
);

$loop->run;
```

## Address modes

Exactly one of these is required:

- **host/port**: `host => $host, port => $port`  
  IP literals avoid `getaddrinfo`. Hostnames use synchronous `getaddrinfo`.

- **unix**: `unix => '/path/to.sock'`

- **sockaddr**: `sockaddr => $packed, family => $AF_*`  
  `family` is required and never inferred.

## Examples

See `examples/`.

## Performance notes

- IP literals avoid `getaddrinfo`.
- Hostnames may block due to synchronous `getaddrinfo`.
- For strict nonblocking behavior in all cases, use **sockaddr mode** with a pre-resolved address.

## License

Same terms as Perl itself.
