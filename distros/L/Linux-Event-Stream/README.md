# Linux::Event::Stream

[![CI](https://github.com/haxmeister/perl-linux-event-stream/actions/workflows/ci.yml/badge.svg)](https://github.com/haxmeister/perl-linux-event-stream/actions/workflows/ci.yml)

Buffered, backpressure-aware I/O for Linux::Event.

## Overview

Linux::Event::Stream wraps a nonblocking file descriptor and provides:

- Write buffering
- High/low watermark backpressure (hysteresis latch)
- Graceful close-after-drain
- Optional read throttling

It does **not** create sockets, implement protocols, or modify the event loop.
It is a small policy layer over a file descriptor.

Designed for use with **Linux::Event 0.009+**.

---

## Basic Example

```perl
use v5.36;
use Linux::Event;
use Linux::Event::Stream;

my $loop = Linux::Event->new;

my $stream = Linux::Event::Stream->new(
  loop => $loop,
  fh   => $socket,

  on_read => sub ($stream, $bytes, $data) {
    print "Received: $bytes";
  },

  on_error => sub ($stream, $errno, $data) {
    warn "I/O error: $errno";
  },

  on_close => sub ($stream, $data) {
    print "Connection closed\n";
  },

  high_watermark => 1_048_576,
  low_watermark  =>   262_144,
);

$stream->write("hello\n");

$loop->run;

```

## Framed Example (newline-delimited messages)

Stream can also run in framed/message mode, where it buffers incoming bytes
internally and emits complete messages using a codec.

```perl
use v5.36;
use Linux::Event;
use Linux::Event::Stream;

my $loop = Linux::Event->new;

my $stream = Linux::Event::Stream->new(
  loop       => $loop,
  fh         => $socket,
  codec      => 'line',
  on_message => sub ($stream, $line, $data) {
    $stream->write_message("echo: $line");
  },
);

$loop->run;
```

## Notes

* Raw mode uses C<on_read> and delivers arbitrary byte chunks (TCP and pipes do
  not preserve message boundaries).
* Framed/message mode uses C<codec + on_message> and delivers complete
  messages.
* Built-in codec aliases: C<line>, C<netstring>, C<u32be>.
* To implement your own framing/encoding, see L<Linux::Event::Stream::Codec>.
