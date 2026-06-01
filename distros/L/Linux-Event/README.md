[![CI](https://github.com/haxmeister/perl-linux-event/actions/workflows/ci.yml/badge.svg)](https://github.com/haxmeister/perl-linux-event/actions/workflows/ci.yml)

# Linux::Event

Linux::Event is a Linux-native readiness event loop for Perl. It currently
ships with an epoll backend and is built around small Linux kernel primitives:
timerfd, signalfd, eventfd, and pidfd.

`Linux::Event->new` returns a `Linux::Event::Loop` object directly. Additional
readiness backends may be added in future releases.

## Architecture

The goal is a small, explicit, composable foundation for building event-driven
systems on Linux.

```text
Linux::Event
    |
    +-- Linux::Event::Loop
            |
            +-- Linux::Event::Backend::Epoll
```

## What this distribution contains

Core modules in this repository:

- `Linux::Event` - front door returning `Linux::Event::Loop`
- `Linux::Event::Loop` - public readiness loop
- `Linux::Event::Backend` - readiness backend contract
- `Linux::Event::Backend::Epoll` - built-in epoll backend
- `Linux::Event::Watcher` - mutable watcher handle
- `Linux::Event::Signal` - signalfd adaptor
- `Linux::Event::Wakeup` - eventfd-backed wakeup primitive
- `Linux::Event::Pid` - pidfd-backed process exit notifications
- `Linux::Event::Scheduler` - internal monotonic deadline queue

## Quick start

```perl
use v5.36;
use Linux::Event;

my $loop = Linux::Event->new;

$loop->after(0.250, sub ($loop) {
  say "timer fired";
  $loop->stop;
});

$loop->run;
```

You may pass `backend => 'epoll'` explicitly, but it is also the default:

```perl
my $loop = Linux::Event->new(backend => 'epoll');
```

## Core API

The loop exposes a focused readiness API:

- `watch($fh, read => ..., write => ..., error => ...)`
- `unwatch($fh)`
- `after($seconds, $cb)`
- `at($deadline_seconds, $cb)`
- `cancel($timer_id)`
- `signal($signal, $cb, %opts)`
- `pid($pid, $cb, %opts)`
- `waker`
- `run`, `run_once`, `stop`
- `clock`, `backend`, `backend_name`, `is_running`

Watcher callbacks receive:

```perl
sub ($loop, $fh, $watcher) { ... }
```

Timer callbacks receive:

```perl
sub ($loop) { ... }
```

Signal callbacks receive:

```perl
sub ($loop, $sig, $count, $data) { ... }
```

Pid callbacks receive:

```perl
sub ($loop, $pid, $status, $data) { ... }
```

## Ecosystem layering

This distribution intentionally stays at the loop-and-primitives layer.
Companion distributions provide higher-level building blocks:

- `Linux::Event::Listen` - server-side socket acquisition
- `Linux::Event::Connect` - client-side nonblocking outbound connect
- `Linux::Event::Stream` - buffered I/O and backpressure for established filehandles
- `Linux::Event::Fork` - asynchronous child-process helpers
- `Linux::Event::Clock` - monotonic time helpers
- `Linux::Event::Timer` - timerfd wrapper used by the core loop

Canonical networking composition:

```text
Listen / Connect
        |
      Stream
        |
   your protocol
```

## Dependencies

Runtime dependencies are intentionally small:

- Perl 5.36 or newer
- `Linux::Epoll`
- `Linux::FD::Event`
- `Linux::FD::Signal`
- `Linux::FD::Pid`
- `Linux::Event::Timer`
- `Linux::Event::Clock`

## Examples

See `examples/` for small programs covering timers, filehandle readiness,
signals, wakeups, pidfds, and epoll regression cases.

## Project status

This project is still pre-1.0. The loop is intentionally focused on readiness
backends so the stable API can stay small and maintainable.
