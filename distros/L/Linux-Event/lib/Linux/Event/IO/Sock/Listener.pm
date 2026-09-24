package Linux::Event::IO::Sock::Listener;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use parent 'Linux::Event::_Socket::Listener';
use Carp qw(croak);

sub new ($class, %option) {
    if (exists $option{stream}) {
        croak 'new(): stream must be a hash reference'
            if ref($option{stream}) ne 'HASH';
        if (exists $option{stream}{class}) {
            my $stream_class = $option{stream}{class};
            croak 'new(): stream class must name a Linux::Event::IO::Sock::Stream subclass'
                if ref($stream_class)
                || !$stream_class->isa('Linux::Event::IO::Sock::Stream');
        }
    }
    return $class->SUPER::new(%option);
}

1;

__END__

=head1 NAME

Linux::Event::IO::Sock::Listener - Accept asynchronous stream connections

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::IO::Sock::Listener;

  my $loop = Linux::Event::Loop->new;

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '127.0.0.1',
      port => 9999,

      stream => {
          on_data => sub ($self, $bytes) {
              $self->write($bytes);
          },
      },
  );

  say "Listening on port " . $listener->port;

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::IO::Sock::Listener> represents a listening stream socket.

It accepts incoming connections and creates a
L<Linux::Event::IO::Sock::Stream> object for each one.

A Listener can listen on:

=over 4

=item *

TCP over IPv4

=item *

TCP over IPv6

=item *

Unix-domain stream sockets

=item *

an already-created listening socket supplied by the application

=back

The most important Listener option is C<stream>.

The C<stream> hash describes what kind of Stream should be created for each
accepted connection and how that Stream should behave.

For example, this creates a simple echo server:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 9000,

      stream => {
          on_data => sub ($self, $bytes) {
              $self->write($bytes);
          },
      },
  );

Every new client gets its own Stream object, and that Stream uses the supplied
C<on_data> callback.

=head1 CREATING A TCP LISTENER

A normal TCP server looks like this:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 5000,

      stream => {
          on_data => sub ($self, $bytes) {
              ...
          },
      },
  );

=head2 host

  host => '0.0.0.0'

The local address to bind.

For example:

  '127.0.0.1'

listens only on the local IPv4 loopback interface, while:

  '0.0.0.0'

requests all IPv4 interfaces.

IPv6 addresses may also be used.

=head2 port

  port => 5000

The TCP port to bind.

Use zero to let the kernel select an available port:

  port => 0

The selected port can then be read with:

  my $port = $listener->port;

This is particularly useful in tests.

=head2 loop

  loop => $loop

Attach the Listener to the Loop immediately.

The option is not required.

A Listener may instead be created detached:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      host => '127.0.0.1',
      port => 5000,
      stream => { ... },
  );

and attached later:

  $loop->add($listener);

=head1 UNIX-DOMAIN LISTENERS

Use C<unix> instead of C<host> and C<port>:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      unix => '/run/my-service.sock',

      stream => {
          on_data => sub ($self, $bytes) {
              ...
          },
      },
  );

This creates a Unix-domain C<SOCK_STREAM> listener.

Linux::Event uses the same Listener and Stream APIs for TCP and Unix-domain
connections.

=head1 THE STREAM RECIPE

The nested C<stream> hash describes the Stream that should be created for every
accepted connection.

The simplest form supplies callbacks directly:

  stream => {
      on_data => sub ($self, $bytes) {
          $self->write($bytes);
      },
  }

The default Stream class is:

  Linux::Event::IO::Sock::Stream

so a simple server does not need to define its own connection subclass.

The recipe may contain:

=over 4

=item *

C<class>

=item *

Stream callbacks

=item *

C<data>

=item *

C<tuning>

=item *

C<tls>

=back

=head2 Stream callbacks

Callbacks inside C<stream> belong to the accepted connection:

  stream => {
      on_ready => sub ($self) {
          ...
      },

      on_data => sub ($self, $bytes) {
          ...
      },

      on_error => sub ($self, $error) {
          ...
      },

      on_close => sub ($self) {
          ...
      },
  }

The available Stream callbacks are:

  on_data
  on_message
  on_messages
  on_ready
  on_transport_ready
  on_drain
  on_eof
  on_error
  on_close

See L<Linux::Event::IO::Sock::Stream> for their behavior.

=head2 class

A server may use a Stream subclass for its accepted connections:

  package ChatConnection;

  use parent 'Linux::Event::IO::Sock::Stream';
  use Linux::Event::Framer 'Delimiter', "\n";

  sub on_message ($self, $message) {
      ...
  }

  package main;

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 5000,

      stream => {
          class => 'ChatConnection',
      },
  );

This is useful when all connections share a protocol, framing rule, TLS
defaults, socket policy, tuning, or callback methods.

=head2 Mixing subclass methods and callbacks

The Stream recipe may still provide callbacks when a Stream subclass is used:

  stream => {
      class => 'ChatConnection',

      on_close => sub ($self) {
          remove_connection($self);
      },
  }

A constructor-style callback in the recipe overrides the same-named subclass
method for Streams created by that Listener.

This lets a reusable protocol class be combined with application-specific
behavior.

=head2 data

  stream => {
      data => $value,
      ...
  }

Set the initial C<data> value for each accepted Stream.

The supplied value becomes the connection's application data.

=head1 WHEN A CONNECTION IS ACCEPTED

Linux::Event accepts the socket, creates the configured Stream object, attaches
that Stream to the same Loop as the Listener, and prepares it for asynchronous
I/O.

For a plain connection, C<on_ready> follows when the Stream is ready for
application use.

For a TLS connection, C<on_ready> waits until the TLS handshake and verification
have completed.

=head1 LISTENER CALLBACKS

The Listener itself also has callbacks.

These are different from callbacks inside the C<stream> recipe.

=head2 on_accept

  on_accept => sub ($self, $stream) {
      say "Accepted a new connection";
  }

Called after a new Stream has been created for an accepted socket.

The second argument is the actual Stream object representing that connection.

This is useful for tasks such as:

=over 4

=item *

keeping a list of connected clients

=item *

assigning application identity to a new connection

=item *

logging connection activity

=item *

performing application-level setup that belongs to the server rather than the
protocol class

=back

For example:

  my %clients;

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 5000,

      stream => {
          on_data => sub ($self, $bytes) {
              ...
          },
      },

      on_accept => sub ($self, $stream) {
          $clients{$stream} = 1;
      },
  );

=head2 on_error

  on_error => sub ($self, $error) {
      warn "Listener error: $error\n";
  }

Called when an asynchronous error belongs to the Listener itself.

This is separate from a Stream's C<on_error>.

For example:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      ...

      stream => {
          on_error => sub ($self, $error) {
              warn "Client connection error: $error\n";
          },
      },

      on_error => sub ($self, $error) {
          warn "Listening socket error: $error\n";
      },
  );

The inner C<on_error> handles connection errors.

The outer C<on_error> handles Listener errors.

=head2 Errors from on_accept

If C<on_accept> dies, Linux::Event closes only the newly accepted connection.

The Listener remains alive.

The error is reported through the Listener's C<on_error> callback.

=head1 USING A LISTENER SUBCLASS

Listener callbacks can also be methods:

  package MyListener;

  use parent 'Linux::Event::IO::Sock::Listener';

  sub on_accept ($self, $stream) {
      say "New client";
  }

A constructor callback overrides the same-named method for that particular
Listener.

For most applications, constructor callbacks are the simpler choice unless
Listener behavior itself is reusable.

=head1 TLS SERVERS

TLS belongs inside the C<stream> recipe because TLS is a property of each
accepted connection.

For example:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 9443,

      stream => {
          class => 'ServerConnection',

          tls => {
              cert_file => '/etc/myapp/server-cert.pem',
              key_file  => '/etc/myapp/server-key.pem',
          },
      },
  );

The Listener prepares reusable server TLS configuration once.

Each accepted Stream receives its own TLS connection state.

Application callbacks see plaintext rather than encrypted wire bytes.

A Stream class does not need to be a special TLS subclass merely because one
Listener uses it with TLS.

For example, the same C<ServerConnection> class could be used by:

  port => 8080

without C<tls>, and by:

  port => 8443

with C<tls>.

See L<Linux::Event::TLS> for the complete TLS configuration.

=head1 STREAM TUNING FOR ACCEPTED CONNECTIONS

A Stream subclass may define its normal C<stream_tuning> defaults.

A particular Listener can override those defaults for every connection it
accepts:

  stream => {
      class => 'ServerConnection',

      tuning => {
          idle_timeout   => 30,
          high_watermark => 2_097_152,
          low_watermark  => 524_288,
      },
  }

These values apply to Streams created by this Listener.

An individual Stream may later change its mutable settings with:

  $stream->tune(...);

The precedence is therefore:

  Stream subclass defaults
      then Listener stream tuning
          then live Stream tune()

See L<Linux::Event::IO::Sock::Stream> for all tuning options.

=head1 LISTENER ACCEPTANCE TUNING

Listener acceptance settings are B<top-level constructor options>.

They belong alongside C<host>, C<port>, and C<stream>. They do not go inside
the Stream recipe and they do not use a separate C<tuning> hash.

For example:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 9999,

      backlog             => 8_192,
      max_accept_per_tick => 512,
      reuseaddr           => 1,
      reuseport           => 1,

      stream => {
          class => 'ServerConnection',

          tuning => {
              idle_timeout   => 30,
              high_watermark => 2_097_152,
          },
      },
  );

In this example:

  backlog
  max_accept_per_tick
  reuseaddr
  reuseport

configure the B<Listener>, while:

  idle_timeout
  high_watermark

configure each accepted B<Stream>.

The following settings affect the listening socket itself rather than the
Streams it creates.

Most applications should leave their defaults unchanged.

=head2 backlog

Default: 4,096.

  backlog => 8192

Requested kernel listen backlog.

It must be a positive integer.

=head2 max_accept_per_tick

Default: 256.

  max_accept_per_tick => 512

Maximum number of connections Linux::Event accepts during one readiness turn.

This exists for fairness.

A busy listening socket should not indefinitely prevent existing connections,
timers, and other resources from running.

A value of zero means to continue accepting until the kernel reports that no
more connections are immediately available.

Zero is required when edge-triggered acceptance is enabled.

=head2 edge_triggered

Default: false.

  edge_triggered => 1

Use edge-triggered accept readiness.

This is an advanced option.

When enabled, C<max_accept_per_tick> must be zero so the accept queue is drained
until it would block.

=head2 reuseaddr

Default: true.

  reuseaddr => 1

Controls C<SO_REUSEADDR> for a Listener created by Linux::Event.

=head2 reuseport

Default: false.

  reuseport => 1

Controls C<SO_REUSEPORT> for a Listener created by Linux::Event.

=head2 v6only

For an IPv6 Listener:

  v6only => 1

controls C<IPV6_V6ONLY>.

When unspecified, the operating-system default is used.

=head2 bind_device

  bind_device => 'eth0'

Bind an Internet Listener to a particular Linux network interface using
C<SO_BINDTODEVICE>.

This is normally unnecessary.

=head1 UNIX SOCKET FILE OPTIONS

Unix-domain listeners have several options relating to the filesystem socket
path.

=head2 unlink

  unlink => 1

Allow an existing socket path to be removed as part of Listener setup.

The default is false.

=head2 unlink_on_close

  unlink_on_close => 1

Remove the owned Unix socket path when the Listener closes.

The default is true.

=head2 permissions

Set filesystem permissions for a newly created Unix-domain socket path.

=head1 ADOPTING AN EXISTING LISTENING SOCKET

A Listener can take an already-created listening socket:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      fh   => $socket,

      stream => {
          on_data => sub ($self, $bytes) {
              ...
          },
      },
  );

This is useful when socket creation or activation is managed elsewhere.

C<owns_socket> controls whether the Listener owns the adopted socket's
lifecycle.

=head1 PAUSING AND RESUMING ACCEPTANCE

=head2 pause

  $listener->pause;

Temporarily stop accepting new connections while keeping the listening socket
open.

Existing accepted Streams continue operating normally.

=head2 resume

  $listener->resume;

Resume accepting new connections.

This can be useful when the application intentionally wants to limit admission
without shutting down the server.

=head1 CLOSING A LISTENER

=head2 close

  $listener->close;

Stop listening and end the Listener's ownership of the socket.

Existing accepted Streams are separate resources and are not automatically
closed merely because the Listener closes.

=head2 detach

  my $fh = $listener->detach;

Remove the listening socket from Linux::Event and return the still-open socket
handle.

Detachment is terminal for the Listener object.

=head1 INFORMATION METHODS

=head2 port

  my $port = $listener->port;

Return the bound TCP port.

This is especially useful when the Listener was created with:

  port => 0

and the kernel selected the actual port.

=head2 family

Return the socket family in descriptive form.

=head2 family_number

Return the numeric socket family.

=head2 is_tcp

Return true for an Internet TCP Listener.

=head2 is_unix

Return true for a Unix-domain Listener.

=head2 state

Return the Listener's current lifecycle state.

Possible states include:

  unattached
  listening
  paused
  closed
  failed
  detached

=head1 RESOURCE EXHAUSTION

If the process temporarily runs out of resources while accepting connections,
Linux::Event pauses acceptance before reporting the error.

This prevents a busy readable listening socket from repeatedly generating the
same failure in a tight loop.

The failure is then delivered through the Listener's C<on_error> callback.

=head1 PERFORMANCE MODEL

The Stream recipe is prepared when the Listener is constructed.

Linux::Event does not rebuild the Stream class, callback, TLS, and tuning
configuration from scratch every time a connection is accepted.

This allows accepted connections to use the same convenient callback and
subclass APIs without adding repeated configuration work to the accept path.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::Loop>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::TLS>,
L<Linux::Event::Error>,
F<docs/SOCKET-CONNECTIONS.md>,
F<docs/SOCKET-CONFIGURATION.md>.

=cut
