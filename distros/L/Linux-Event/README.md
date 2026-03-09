[![CI](https://github.com/haxmeister/perl-linux-event/actions/workflows/ci.yml/badge.svg)](https://github.com/haxmeister/perl-linux-event/actions/workflows/ci.yml)

# Linux::Event

Linux::Event is a Linux-native event-loop distribution for Perl with two peer execution models:

- **Reactor** for readiness-based I/O
- **Proactor** for completion-based I/O

The public front door is `Linux::Event::Loop`, and `Linux::Event->new` is a convenient shortcut to it.

<<<<<<< HEAD
## Architecture
=======
The goal is a **small, explicit, composable foundation** for building
high-performance event-driven systems on Linux. Model selection is explicit
and mandatory: choose reactor or proactor when constructing a loop.
>>>>>>> 1401c31 (prep for cpan and release, new tool added)

```text
Linux::Event::Loop
    |
    +-- Linux::Event::Reactor
    |       |
    |       +-- Linux::Event::Reactor::Backend::Epoll
    |
    +-- Linux::Event::Proactor
            |
            +-- Linux::Event::Proactor::Backend::Uring
            +-- Linux::Event::Proactor::Backend::Fake
```

## What this distribution contains

Core modules in this repository:

- `Linux::Event` - front door shortcut returning `Linux::Event::Loop`
- `Linux::Event::Loop` - selector and delegating public API
- `Linux::Event::Reactor` - readiness engine
- `Linux::Event::Reactor::Backend` - readiness backend contract
- `Linux::Event::Reactor::Backend::Epoll` - epoll backend
- `Linux::Event::Watcher` - mutable reactor watcher handle
- `Linux::Event::Signal` - signalfd adaptor
- `Linux::Event::Wakeup` - eventfd-backed wakeup primitive
- `Linux::Event::Pid` - pidfd-backed process exit notifications
- `Linux::Event::Scheduler` - internal monotonic deadline queue
- `Linux::Event::Proactor` - completion engine
- `Linux::Event::Proactor::Backend` - completion backend contract
- `Linux::Event::Proactor::Backend::Uring` - io_uring backend
- `Linux::Event::Proactor::Backend::Fake` - deterministic testing backend
- `Linux::Event::Operation` - in-flight operation object
- `Linux::Event::Error` - lightweight proactor error object

## Ecosystem layering

<<<<<<< HEAD
This distribution intentionally stays at the loop-and-primitives layer.
=======
Linux::Event
    Front door for the Linux::Event ecosystem. Construct a
    Linux::Event::Loop by explicitly choosing reactor or proactor mode.
>>>>>>> 1401c31 (prep for cpan and release, new tool added)

Companion distributions provide higher-level networking and process-building blocks:

- `Linux::Event::Listen` - server-side socket acquisition
- `Linux::Event::Connect` - client-side nonblocking connect
- `Linux::Event::Stream` - buffered I/O and backpressure for established filehandles
- `Linux::Event::Fork` - asynchronous child-process helpers
- `Linux::Event::Clock` - monotonic time helpers
- `Linux::Event::Timer` - timerfd wrapper used by the reactor

Canonical networking composition:

```text
Listen / Connect
<<<<<<< HEAD
        |
      Stream
        |
   your protocol
```
=======
        
      Stream
        
  Application protocol
>>>>>>> 1401c31 (prep for cpan and release, new tool added)

## Choosing a model

<<<<<<< HEAD
Use the **reactor** when you want readiness notifications over existing filehandles:
=======
Linux::Event::Listen  Linux::Event::Stream  your protocol
>>>>>>> 1401c31 (prep for cpan and release, new tool added)

```perl
use v5.36;
use Linux::Event;

<<<<<<< HEAD
my $loop = Linux::Event->new(model => 'reactor');
=======
Linux::Event::Connect  Linux::Event::Stream  your protocol
>>>>>>> 1401c31 (prep for cpan and release, new tool added)

$loop->after(0.250, sub ($loop) {
  say "timer fired";
  $loop->stop;
});

$loop->run;
```

Use the **proactor** when you want explicit operation objects and completion callbacks:

```perl
use v5.36;
use Linux::Event::Loop;

my $loop = Linux::Event::Loop->new(
  model   => 'proactor',
  backend => 'uring',
);

my $op = $loop->read(
  fh          => $fh,
  len         => 4096,
  on_complete => sub ($op, $result, $data) {
    return if $op->is_cancelled;
    die $op->error->message if $op->failed;

    say "read $result->{bytes} bytes";
  },
);

while ($loop->live_op_count) {
  $loop->run_once;
}
```

## Installation

Development install:

```bash
perl Makefile.PL
make
make test
make install
```

Primary dependencies include:

<<<<<<< HEAD
- Linux
- `Linux::Epoll`
- `Linux::Event::Clock >= 0.011`
- `Linux::Event::Timer >= 0.010`
- `IO::Uring` and `Time::Spec` for the real proactor backend
=======
    Linux
    Linux::Epoll
    Linux::Event::Clock >= 0.011
    Linux::Event::Timer >= 0.010
    IO::Uring and Time::Spec for proactor mode
>>>>>>> 1401c31 (prep for cpan and release, new tool added)

The proactor test suite also supports a fake backend for deterministic testing.

## Examples

The `examples/` directory is organized around the current architecture and includes:

<<<<<<< HEAD
- reactor timers, watchers, signals, wakeups, and pidfd examples
- proactor timer, read/write, and socket lifecycle examples
- deeper reactor benchmarking and regression scripts
=======
    my $loop = Linux::Event->new(
        model => 'reactor',
    );
>>>>>>> 1401c31 (prep for cpan and release, new tool added)

The CI workflow syntax-checks all examples so they do not silently rot.

## Status

<<<<<<< HEAD
This project is still pre-1.0 and is being actively refined toward a cohesive forward-looking architecture. Large structural cleanup is expected during this stage so the eventual stable API lands in a cleaner shape.
=======
---------------------------------------------------------------------

## Additional Linux primitives

Linux::Event integrates several Linux kernel facilities.

Signals via signalfd

    $loop->signal('INT', sub ($loop, $sig) {
        $loop->stop;
    });

Wakeups via eventfd

    my $w = $loop->waker(sub ($loop) {
        say "woken";
    });

Process exit notifications via pidfd

    $loop->pid($pid, sub ($loop, $pid, $status) {
        say "child exited";
    });

See the examples/ directory for complete scripts.

---------------------------------------------------------------------

## Example: TCP server

    use v5.36;
    use Linux::Event;
    use Linux::Event::Listen;
    use Linux::Event::Stream;

    my $loop = Linux::Event->new(
        model => 'reactor',
    );

    Linux::Event::Listen->new(
        loop => $loop,
        host => '127.0.0.1',
        port => 3000,

        on_accept => sub ($loop, $fh, $peer, $listen) {

            Linux::Event::Stream->new(
                loop => $loop,
                fh   => $fh,

                codec => 'line',

                on_message => sub ($stream, $line) {
                    $stream->write_message("echo: $line");
                },
            );
        },
    );

$loop->run;
>>>>>>> 1401c31 (prep for cpan and release, new tool added)

## License

Same terms as Perl itself.
