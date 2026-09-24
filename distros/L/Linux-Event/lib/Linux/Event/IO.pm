package Linux::Event::IO;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

1;

__END__

=head1 NAME

Linux::Event::IO - Application data I/O resources

=head1 SYNOPSIS

Choose the concrete resource that matches the kind of I/O you need:

  use Linux::Event::IO::Pipe;
  use Linux::Event::IO::TTY;
  use Linux::Event::IO::Sock::Stream;
  use Linux::Event::IO::Sock::Listener;
  use Linux::Event::IO::Sock::Dgram;

=head1 DESCRIPTION

C<Linux::Event::IO> is the namespace for Linux::Event resources that move
application data.

It is a category, not a generic I/O object.

Applications normally use one of the concrete classes beneath it.

=head1 CONCRETE I/O TYPES

=head2 Pipe

L<Linux::Event::IO::Pipe> provides ordered-byte I/O over pipes and compatible
file descriptors.

It supports the same ordered-byte buffering, framing, backpressure, and
callback model used by Stream and TTY.

=head2 TTY

L<Linux::Event::IO::TTY> provides asynchronous ordered-byte I/O for terminals
and PTYs.

TTY handles supplied by the application are borrowed by default unless
ownership is requested explicitly.

=head2 Stream socket

L<Linux::Event::IO::Sock::Stream> represents a connected C<SOCK_STREAM>
socket.

This includes:

  TCP over IPv4
  TCP over IPv6
  Unix-domain stream sockets

The socket family is configuration, not a separate Perl class hierarchy.

=head2 Listener

L<Linux::Event::IO::Sock::Listener> accepts incoming stream-socket
connections and creates Stream objects for them.

=head2 Datagram socket

L<Linux::Event::IO::Sock::Dgram> represents C<SOCK_DGRAM> sockets such as UDP
and Unix-domain datagram sockets.

Datagrams preserve packet boundaries rather than exposing one ordered byte
stream.

=head1 ORDERED-BYTE RESOURCES

Pipe, TTY, and Stream share the same fundamental ordered-byte model.

They can operate in raw mode:

  on_data => sub ($self, $bytes) {
      ...
  }

or a subclass can declare native message framing:

  package LineStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $line) {
      ...
  }

Built-in framing therefore belongs to ordered-byte I/O generally.

It is not specifically a socket feature.

=head1 CALLBACKS AND SUBCLASSES

Concrete I/O resources support constructor callbacks where appropriate.

For example:

  my $pipe = Linux::Event::IO::Pipe->new(
      read_fh => $read_fh,

      on_data => sub ($self, $bytes) {
          ...
      },
  );

Subclasses remain useful when behavior is reusable or when the resource needs
class-level policy such as:

  framing
  TLS
  socket defaults
  ordered-byte tuning

For example:

  package ProtocolStream;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'U32BE';

Constructor callbacks and subclass methods are therefore complementary.

A constructor callback can override the corresponding named method for one
object without changing its class-level protocol policy.

=head1 LOOP ATTACHMENT

Concrete I/O resources follow the normal Linux::Event attachment model.

A resource can commonly be created with:

  loop => $loop

or created detached and added later:

  my $stream = MyStream->new(
      fh => $fh,
  );

  $loop->add($stream);

The concrete resource documentation describes any lifecycle details specific
to that type.

=head1 IO AND KERNEL ARE DIFFERENT CATEGORIES

C<Linux::Event::IO> contains resources primarily concerned with moving
application data.

Kernel notification and state resources instead live below
L<Linux::Event::Kernel>, including:

  Timer
  Signal
  Event
  Inotify
  Process

This distinction is organizational rather than a second event-loop system.

All of these resources attach to the same L<Linux::Event::Loop>.

=head1 THERE IS NO GENERIC IO OBJECT

This is not intended:

  Linux::Event::IO->new(...);

Choose the concrete resource whose Linux semantics match the job instead.

For example:

  byte stream over a pipe
      Linux::Event::IO::Pipe

  terminal or PTY
      Linux::Event::IO::TTY

  connected TCP or Unix stream socket
      Linux::Event::IO::Sock::Stream

  listening stream socket
      Linux::Event::IO::Sock::Listener

  UDP or Unix datagram socket
      Linux::Event::IO::Sock::Dgram

This keeps the public API explicit about what Linux resource is actually being
managed.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::IO::Pipe>,
L<Linux::Event::IO::TTY>,
L<Linux::Event::IO::Sock>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Sock::Listener>,
L<Linux::Event::IO::Sock::Dgram>,
L<Linux::Event::Kernel>,
L<Linux::Event::Framer>.

=cut
