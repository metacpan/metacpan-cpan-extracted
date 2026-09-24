package Linux::Event;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

1;

__END__

=head1 NAME

Linux::Event - Fast event-driven programming for Linux

=head1 SYNOPSIS

  use Linux::Event::Loop;
  use Linux::Event::IO::Sock::Stream;

  my $loop = Linux::Event::Loop->new;

  my $client = Linux::Event::IO::Sock::Stream->connect(
      loop => $loop,
      host => '127.0.0.1',
      port => 9999,

      on_data => sub ($self, $bytes) {
          print $bytes;
      },

      on_error => sub ($self, $error) {
          warn "$error\n";
          $loop->stop;
      },
  );

  $loop->run;

=head1 DESCRIPTION

Linux::Event is a Linux-only event system for Perl.

It lets one program efficiently handle many things at the same time, such as:

=over 4

=item *

network connections

=item *

listening servers

=item *

timers

=item *

signals

=item *

child processes

=item *

pipes and terminals

=item *

filesystem changes

=item *

application-generated events

=back

The central object is a L<Linux::Event::Loop>.

You create resources, such as a socket or timer, add them to the loop, and tell
them what Perl code to call when something happens.

The loop then waits for events and dispatches them as they occur.

A typical Linux::Event program therefore follows this pattern:

  my $loop = Linux::Event::Loop->new;

  # Create sockets, timers, processes, etc.

  $loop->run;

Linux::Event is built specifically for Linux and uses Linux facilities such as
epoll, timerfd, signalfd, eventfd, pidfd, and inotify.

You normally do not need to work with those Linux interfaces directly.
Linux::Event wraps them in Perl objects.

=head1 THE EVENT LOOP

The L<Linux::Event::Loop> is the heart of a Linux::Event application.

A resource can usually be attached to a loop when it is created:

  my $timer = Linux::Event::Kernel::Timer->new(
      loop => $loop,
      after => 2,
      on_timer => sub ($self) {
          say "Two seconds have passed";
      },
  );

or it can be created first and added later:

  my $timer = Linux::Event::Kernel::Timer->new(
      after => 2,
      on_timer => sub ($self) {
          say "Two seconds have passed";
      },
  );

  $loop->add($timer);

Once the resources are ready, run the loop:

  $loop->run;

The loop waits until something needs attention and then calls the appropriate
callback.

=head1 CALLBACKS

Most Linux::Event resources accept callbacks in their constructors.

For example:

  my $timer = Linux::Event::Kernel::Timer->new(
      loop => $loop,
      after => 1,
      on_timer => sub ($self) {
          say "Timer fired";
      },
  );

Callbacks are ordinary Perl coderefs, so they can use lexical variables from
the surrounding program:

  my $count = 0;

  my $timer = Linux::Event::Kernel::Timer->new(
      loop => $loop,
      after => 1,
      on_timer => sub ($self) {
          $count++;
          say "Count is now $count";
      },
  );

Many resource classes can also be subclassed and callbacks can be implemented
as methods.

Constructor callbacks are usually the simplest choice for small programs.
Subclassing becomes useful when you want to reuse the same behavior or
configuration for many objects.

=head1 I/O

Modules under C<Linux::Event::IO> represent resources used to move application
data.

=head2 Stream sockets

L<Linux::Event::IO::Sock::Stream> represents a connected stream socket.

It can be used for TCP, Unix-domain stream sockets, clients, and accepted
server connections.

For example:

  my $client = Linux::Event::IO::Sock::Stream->connect(
      loop => $loop,
      host => 'example.com',
      port => 80,

      on_ready => sub ($self) {
          $self->send("GET / HTTP/1.0\r\n\r\n");
      },

      on_data => sub ($self, $bytes) {
          print $bytes;
      },
  );

=head2 Listeners

L<Linux::Event::IO::Sock::Listener> listens for incoming stream connections.

A Listener creates a Stream for each accepted connection.

=head2 Datagram sockets

L<Linux::Event::IO::Sock::Dgram> provides datagram sockets, including UDP and
Unix-domain datagrams.

Unlike a Stream, each received datagram remains a separate message.

=head2 Pipes

L<Linux::Event::IO::Pipe> provides asynchronous byte I/O for pipes and FIFOs.

It can also be used with pipes connected to child processes.

=head2 Terminals

L<Linux::Event::IO::TTY> provides asynchronous I/O for terminals and
pseudo-terminals.

=head1 KERNEL EVENTS

Modules under C<Linux::Event::Kernel> represent notifications and services
provided by the Linux kernel.

=head2 Timers

L<Linux::Event::Kernel::Timer> provides one-shot and repeating timers.

=head2 Signals

L<Linux::Event::Kernel::Signal> lets the event loop respond to Unix signals
without traditional asynchronous Perl signal handlers.

=head2 Processes

L<Linux::Event::Kernel::Process> can start and monitor child processes.

It can also connect their standard input, output, and error streams to the
event loop.

=head2 Filesystem changes

L<Linux::Event::Kernel::Inotify> watches files and directories for changes.

For example, an application can be notified when a file is modified, created,
deleted, renamed, or moved.

=head2 Application events

L<Linux::Event::Kernel::Event> provides eventfd-backed notifications.

It is useful when another thread or process needs to wake the event loop.

=head1 STREAMS AND MESSAGES

L<Linux::Event::IO::Sock::Stream>, L<Linux::Event::IO::Pipe>, and
L<Linux::Event::IO::TTY> all work with ordered streams of bytes.

For raw byte-oriented protocols, use C<on_data>:

  on_data => sub ($self, $bytes) {
      ...
  }

Linux::Event can also split an incoming byte stream into complete messages
before calling your application.

This is called framing.

For example, a line-oriented protocol can declare that every newline ends a
message:

  package LineProtocol;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $message) {
      say "Received: $message";
  }

See L<Linux::Event::Framer> for the available framing methods.

=head1 TLS

L<Linux::Event::TLS> adds TLS support to
L<Linux::Event::IO::Sock::Stream> subclasses.

TLS policy is normally declared once in a Stream subclass so every instance of
that class uses the same TLS configuration.

=head1 SUBCLASSING

You do not need to create a subclass merely to use Linux::Event.

For many programs, constructor callbacks are enough:

  my $stream = Linux::Event::IO::Sock::Stream->new(
      fh => $socket,

      on_data => sub ($self, $bytes) {
          ...
      },
  );

Subclassing is useful when many objects should share the same behavior or
configuration.

For example:

  package ChatConnection;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $message) {
      ...
  }

A subclass can define reusable callbacks, framing, TLS configuration, socket
settings, and performance tuning.

Constructor callbacks can still be supplied for individual objects when
per-object behavior is needed.

=head1 DEFERRED WORK

The event loop can schedule a callback to run after the current work has
finished:

  $loop->defer(sub {
      say "This runs shortly, but not recursively inside the current callback";
  });

This is useful when work should happen soon but should not interrupt the
callback that is currently running.

See L<Linux::Event::Loop> for details.

=head1 FORKING

Linux::Event provides a loop-aware fork operation for applications that need
to create child processes while Linux::Event resources already exist.

  my $pid = $loop->fork(
      share => [ $listener ],
      move  => [ $stream ],
      clone => [ $timer ],
  );

The disposition of a resource determines whether it remains usable in the
parent, child, or both.

Not every resource supports every disposition.

See L<Linux::Event::Loop> for the complete fork rules before using this
feature.

=head1 LOW-LEVEL DESCRIPTOR WATCHING

Most applications should use the resource classes described above.

When necessary, L<Linux::Event::Loop> can also watch a file descriptor
directly:

  my $watch = $loop->watch(
      fd   => $fd,
      read => sub {
          ...
      },
  );

This provides direct access to descriptor readiness without requiring a
higher-level Linux::Event resource object.

=head1 OTHER USEFUL MODULES

=head2 Linux::Event::Address

L<Linux::Event::Address> represents IPv4, IPv6, and Unix-domain socket
addresses.

=head2 Linux::Event::Error

L<Linux::Event::Error> provides structured error objects used throughout the
distribution.

=head2 Linux::Event::Framer

L<Linux::Event::Framer> turns an incoming byte stream into complete messages.

=head2 Linux::Event::TLS

L<Linux::Event::TLS> provides TLS configuration for Stream subclasses.

=head1 WHERE TO START

If you are new to Linux::Event, the most useful modules to read next are:

=over 4

=item 1.

L<Linux::Event::Loop> - creating and running the event loop

=item 2.

L<Linux::Event::IO::Sock::Stream> - connected network sockets

=item 3.

L<Linux::Event::IO::Sock::Listener> - accepting network connections

=item 4.

L<Linux::Event::Kernel::Timer> - scheduling work in the future

=item 5.

L<Linux::Event::Kernel::Process> - running child processes

=back

The other modules can then be learned as your application needs them.

=head1 PLATFORM

Linux::Event runs only on Linux.

The distribution requires Perl 5.36 or newer.

Building the complete distribution also requires suitable Linux headers, a C
compiler, OpenSSL development files, and Linux facilities used by the
individual resource classes.

A Linux 5.4 or newer runtime is required for pidfd process support.

Perl ithreads are not required.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
