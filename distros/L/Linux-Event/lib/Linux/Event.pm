package Linux::Event;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.116';

1;

__END__

=head1 NAME

Linux::Event - Linux-native reactor, I/O, and kernel event facilities

=head1 SYNOPSIS

  use Linux::Event::Loop;
  use Linux::Event::IO::Sock::Stream;

  my $loop = Linux::Event::Loop->new;

  my $client = Linux::Event::IO::Sock::Stream->connect(
      loop => $loop,
      host => '127.0.0.1',
      port => 9999,
      on_data => sub ($stream, $bytes) {
          print $bytes;
      },
      on_error => sub ($stream, $error) {
          warn "$error\n";
          $loop->stop;
      },
  );

  $loop->run;

=head1 DESCRIPTION

Linux::Event is a Linux-only asynchronous I/O distribution built around an
XS-first epoll reactor. Its public resource model is divided into two semantic
namespaces:

=over 4

=item * L<Linux::Event::IO>

Application data I/O. Applications select a concrete leaf for the Linux
facility they are using, such as a pipe, terminal, stream socket, listener, or
datagram socket.

=item * L<Linux::Event::Kernel>

Kernel notification and state facilities such as timers, signals, eventfd
notifications, and process lifecycle handling.

=back

C<Linux::Event::IO> and C<Linux::Event::Kernel> are namespace categories, not
generic objects and not public subclassing bases. Public classes are concrete
semantic leaves. Shared buffering, framing, socket, descriptor, and lifecycle
machinery remains private implementation detail.

Every attachable resource accepts C<loop =E<gt> $loop> where supported. A
resource may instead be constructed unattached and passed to
C<< $loop->add($object) >>. Low-level descriptor readiness remains available
directly from L<Linux::Event::Loop>.

=head1 CALLBACKS, SUBCLASSING, AND TUNING

Public resources accept constructor callback coderefs, so an application can
use the concrete leaf directly and capture ordinary lexical state. A
constructor callback is resolved once per object and overrides a same-named
subclass method.

Subclassing is a complementary performance and organization feature, not a
requirement imposed merely to obtain a callback. A protocol subclass can
declare native L<Linux::Event::Framer> policy, L<Linux::Event::TLS> policy,
socket configuration, and C<stream_tuning>, C<datagram_options>, or
C<process_options> tuning once for every instance. Named callbacks and class
policy are validated and cached once per subclass rather than rediscovered on
each readiness event.

The common pattern is therefore to put reusable protocol, transport, and
tuning policy in a subclass while supplying closures for per-instance lexical
state. Raw resources with no reusable class policy can be constructed directly.

=head1 I/O MODULES

=over 4

=item * L<Linux::Event::IO::Pipe>

Ordered byte I/O for anonymous pipes, FIFOs, and child-process pipe handles.
It may be read-only, write-only, or use separate read and write pipe handles.

=item * L<Linux::Event::IO::TTY>

Ordered byte I/O for terminals and pseudo-terminals. The class validates that
its configured handles are terminal devices.

=item * L<Linux::Event::IO::Sock::Stream>

Connected C<SOCK_STREAM> sockets. IPv4, IPv6, and Unix-domain sockets use the
same leaf; address family is configuration rather than a different class.
This leaf owns outbound C<connect>, socket options, addresses, kernel
half-close behavior, buffering, framing, backpressure, and optional TLS.

=item * L<Linux::Event::IO::Sock::Listener>

Listening C<SOCK_STREAM> sockets for TCP and Unix-domain endpoints. Accepted
connections are constructed as a chosen C<Linux::Event::IO::Sock::Stream>
class.

=item * L<Linux::Event::IO::Sock::Dgram>

C<SOCK_DGRAM> sockets preserving packet boundaries and peer addresses for UDP
and Unix-domain datagrams.

=back

=head1 KERNEL MODULES

=over 4

=item * L<Linux::Event::Kernel::Timer>

One-shot and recurring monotonic timers with constructor or subclass callbacks.

=item * L<Linux::Event::Kernel::Signal>

Signalfd subscriptions with constructor or subclass callbacks and native fan-out.

=item * L<Linux::Event::Kernel::Event>

Eventfd-backed notifications. Foreign threads or forked children can signal a
registered object without transferring Perl callbacks or Perl values.

=item * L<Linux::Event::Kernel::Process>

Pidfd lifecycle notification, native process spawning, decoded exit status,
signals, and asynchronous standard I/O.

=back

=head1 SUPPORTING MODULES

=over 4

=item * L<Linux::Event::Loop>

XS-first epoll reactor, native descriptor registry, query-driven introspection,
and optional profiling.

=item * L<Linux::Event::Framer>

Declarative native framing for ordered-byte I/O subclasses. Framing applies to
pipe, TTY, and C<SOCK_STREAM> leaves because it is a byte-stream behavior, not
a socket-specific feature.

=item * L<Linux::Event::TLS>

Declarative OpenSSL TLS policy for C<Linux::Event::IO::Sock::Stream>
subclasses.

=item * L<Linux::Event::Error>

Structured errors shared by I/O, process, connection, and transport paths.

=item * L<Linux::Event::Address>

Lazy IPv4, IPv6, and Unix socket-address values.

=back

=head1 ORDERED-BYTE CALLBACK MODEL

C<Linux::Event::IO::Pipe>, C<Linux::Event::IO::TTY>, and
C<Linux::Event::IO::Sock::Stream> support both subclass methods and
constructor-supplied coderefs for application callbacks. Constructor callbacks
are ordinary Perl closures and may capture lexical application state. They
override same-named class methods for that object.

The ordered-byte callback names are C<on_data>, C<on_message>, C<on_messages>,
C<on_ready>, C<on_transport_ready>, C<on_drain>, C<on_eof>, C<on_error>, and
C<on_close>. C<IO::Sock::Stream-E<gt>connect()> accepts the same callback set as
C<new()>.

Subclassing is therefore not required merely to obtain callback scope. A raw
stream socket, Pipe, or TTY can be used directly when no class-level protocol
policy is needed. Class declarations remain the correct place for reusable
policy such as C<stream_tuning()>, a L<Linux::Event::Framer> declaration,
socket policy, or L<Linux::Event::TLS> policy.

For example, framing remains class policy while message handling may be a
constructor closure:

  package LineProtocol;
  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

  package main;
  my $connection = LineProtocol->new(
      fh => $socket,
      on_message => sub ($stream, $message) {
          process_message($message);
      },
  );

The effective input callback is selected during construction and retained as
one cached CV in native ordered-byte state. Steady-state input does not perform
method lookup, object-hash callback lookup, or a method-versus-closure branch.

A L<Linux::Event::IO::Sock::Listener> can provide the same ordered-byte
callback options as templates for all accepted Streams. One supplied callback
CV is reused for the accepted connections; the Listener's own C<on_accept> and
Listener-error policy remain Listener subclass methods.

See F<docs/FIRST-CLASS-STREAM-CALLBACKS.md> for the full callback, precedence,
transition, and Listener-sharing contract.

=head1 PUBLIC MODEL

Applications use the concrete leaf that describes the resource. Raw
ordered-byte leaves can be constructed directly with callback coderefs; a
subclass holds reusable framing, tuning, socket/TLS policy, or method callbacks.
For example:

  package Protocol;
  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $message) {
      $self->send($message);
  }

The same class method can be overridden for one object while retaining lexical
state:

  my $stream = Protocol->new(
      fh         => $connected_socket,
      on_message => sub ($stream, $message) {
          store_message($database, $message);
          $stream->send($message);
      },
  );

Raw C<IO::Sock::Stream>, C<IO::Pipe>, and C<IO::TTY> objects similarly accept
C<on_data>. Ordered-byte lifecycle callbacks can also be supplied to the
constructor. See L<Linux::Event::IO::Sock::Stream> and
F<docs/FIRST-CLASS-STREAM-CALLBACKS.md> for the complete callback matrix.

A listener then uses that completed stream-socket class in its generated-Stream
recipe:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 9999,
      stream => {
          class      => 'Protocol',
          on_message => sub ($stream, $message) {
              $stream->send($message);
          },
      },
  );

The category names C<IO> and C<Kernel> do not imply a Perl inheritance tree.
Likewise, implementation sharing does not make private machinery part of the
public API. The public name identifies the final semantic resource; internal
layers may be reorganized without changing that leaf.

C<< $loop->watch(fd =E<gt> $fd, read =E<gt> $callback) >> remains available
for direct descriptor readiness. It returns an opaque native registration
handle with operations such as C<cancel>, C<enable_read>, and
C<disable_write>. That registration is not a named public subclassing class.

=head1 PLATFORM

Linux only. Building the complete distribution requires Linux headers with
pidfd syscall definitions, a Linux 5.4 or newer runtime for pidfd status,
a libc providing C<posix_spawn_file_actions_addchdir_np>, and OpenSSL 1.1.1 or
newer development files. Perl ithreads are not required. Configuration on an
unsupported operating system exits with an C<OS unsupported> result so
automated smoke systems can classify the distribution as not applicable.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
