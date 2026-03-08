# Linux::Event::Listen

[![CI](https://github.com/haxmeister/perl-linux-event-listen/actions/workflows/ci.yml/badge.svg)](https://github.com/haxmeister/perl-linux-event-listen/actions/workflows/ci.yml)


Listening sockets for **Linux::Event**, supporting both TCP and UNIX domain sockets.

## Install

```bash
cpanm Linux::Event::Listen
```

## Usage (TCP)

```perl
use v5.36;
use Linux::Event;
use Linux::Event::Listen;

my $loop = Linux::Event->new;

my $listen = Linux::Event::Listen->new(
  loop => $loop,
  host => '127.0.0.1',
  port => 3000,

  on_accept => sub ($loop, $client_fh, $peer, $listen) {
    # You own $client_fh (already non-blocking).
    ...
  },
);

$loop->run;
```


### Canonical server pattern: Listen + Stream + line codec

If you are building a message-oriented protocol over TCP (for example, one JSON
value per line), a common pattern is to wrap each accepted client socket in
L<Linux::Event::Stream> and let Stream handle buffering and framing.

This example uses Stream's built-in C<line> codec (Linux::Event::Stream 0.002+):

```perl
use v5.36;
use Linux::Event;
use Linux::Event::Listen;
use Linux::Event::Stream;

my $loop = Linux::Event->new;

Linux::Event::Listen->new(
  loop => $loop,
  host => '127.0.0.1',
  port => 3000,

  on_accept => sub ($loop, $client_fh, $peer, $listen) {
    Linux::Event::Stream->new(
      loop       => $loop,
      fh         => $client_fh,
      codec      => 'line',
      on_message => sub ($stream, $line, $data) {
        $stream->write_message("echo: $line");
        $stream->close_after_drain if $line eq 'quit';
      },
    );
  },
);

$loop->run;
```

## Usage (UNIX)

```perl
my $listen = Linux::Event::Listen->new(
  loop   => $loop,
  path   => '/tmp/app.sock',
  unlink => 1,

  on_accept => sub ($loop, $client_fh, $peer, $listen) {
    ...
  },
);
```

## Guarantees and semantics

- Drains `accept()` until `EAGAIN` when edge-triggered readiness is used.
- `max_accept_per_tick` limits work per callback to avoid starving other watchers.
- If `max_accept_per_tick` is explicitly set and `edge_triggered` is not, the listener defaults to level-triggered readiness to avoid edge-trigger stalls.
- Accepted sockets are set non-blocking and handed to user code; you own them.
- `cancel()` is safe to call from inside `on_accept` (listener close may be deferred until the callback returns).

## Error handling

- `on_error` receives a hashref describing the condition (`op`, `error`, optional `errno`).
- `on_emfile` is invoked for `EMFILE`/`ENFILE` accept failures (useful for reserve-FD mitigation).

## UNIX socket lifecycle

- `unlink => 1` removes an existing path before binding.
- `unlink_on_cancel` defaults true for internally-created UNIX sockets; wrap mode (`fh => ...`) will not unlink paths unless `path` was provided.

See the POD in `Linux::Event::Listen` for full details.
