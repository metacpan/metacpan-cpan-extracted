package Linux::Event::IO::Sock::Listener;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.116';

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

Linux::Event::IO::Sock::Listener - asynchronous listening C<SOCK_STREAM> socket

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
          on_data => sub ($stream, $bytes) {
              $stream->write($bytes);
          },
      },
  );

  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::IO::Sock::Listener> owns a listening Linux C<SOCK_STREAM>
socket and is a generator of connected L<Linux::Event::IO::Sock::Stream>
objects. Listener options configure bind/listen/accept behavior. The nested
C<stream =E<gt> {...}> recipe describes the Streams generated for accepted
connections and is resolved once when the Listener is constructed.

TCP and Unix-domain listeners share this class. Socket family is selected by
constructor options, not by subclass hierarchy.

=head1 STREAM RECIPE

The C<stream> hash may contain C<class>, C<tuning>, C<tls>, C<data>, and Stream
callbacks. C<class> defaults to C<Linux::Event::IO::Sock::Stream>, so a simple
raw server does not require a connection subclass:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop => $loop,
      host => '0.0.0.0',
      port => 9000,
      stream => {
          on_data => sub ($stream, $bytes) {
              $stream->write($bytes);
          },
      },
  );

A reusable connection subclass remains the preferred place for framing, named
callback methods, socket policy, and class tuning defaults:

  package ServerConnection;
  use parent 'Linux::Event::IO::Sock::Stream';

  sub stream_tuning ($class) {
      return (
          read_size         => 65_536,
          read_budget_bytes => 262_144,
          idle_timeout      => 60,
      );
  }

  sub on_data ($self, $bytes) {
      $self->write($bytes);
  }

  package main;
  my $listener = Linux::Event::IO::Sock::Listener->new(
      host => '0.0.0.0',
      port => 9000,
      stream => {
          class => 'ServerConnection',
          tuning => {
              read_size    => 131_072,
              idle_timeout => 30,
          },
      },
  );

Recipe tuning overrides C<stream_tuning()> defaults for every Stream generated
by that Listener. A live Stream may subsequently change its own effective
operating values with C<< $stream->tune(...) >>.

C<data> is the initial C<data> value supplied to each generated Stream.
Supported Stream callbacks are C<on_data>, C<on_message>, C<on_messages>,
C<on_ready>, C<on_transport_ready>, C<on_drain>, C<on_eof>, C<on_error>, and
C<on_close>. Callback CVs are retained by the resolved recipe; Linux::Event does
not rebuild the configuration for every accept or every I/O event.

A readable raw Stream must have an effective C<on_data> sink. A framed Stream
must have the message sink required by its effective batching policy, unless a
native consumer supplies that sink. These predictable errors are rejected while
the Listener is being constructed, before any client can be accepted.

=head2 Listener acceptance tuning

Listener settings remain top-level because they configure the listening
resource itself rather than the Streams it generates:

  my $listener = Linux::Event::IO::Sock::Listener->new(
      loop                => $loop,
      host                => '0.0.0.0',
      port                => 9999,
      backlog             => 8_192,
      max_accept_per_tick => 512,
      stream              => {
          class => 'ServerConnection',
      },
  );

=over 4

=item * C<backlog> (default 4,096)

Positive listen backlog requested from the kernel.

=item * C<max_accept_per_tick> (default 256)

Non-negative accept fairness limit. Zero drains until C<EAGAIN> and is required
when C<edge_triggered> is enabled.

=item * C<edge_triggered> (default 0)

Boolean selecting edge-triggered accept readiness.

=item * C<reuseaddr> (default 1)

Boolean controlling C<SO_REUSEADDR> for a created listener.

=item * C<reuseport> (default 0)

Boolean controlling C<SO_REUSEPORT> for a created listener.

=item * C<v6only> (default unspecified)

Optional boolean controlling C<IPV6_V6ONLY> for a created IPv6 listener.

=item * C<bind_device> (default unspecified)

Optional non-empty interface name used with C<SO_BINDTODEVICE> for an Internet
listener.

=back

Unix listener ownership controls are C<unlink> (default false),
C<unlink_on_close> (default true), and optional C<permissions>. C<owns_socket>
controls ownership of an adopted listening C<fh>. These are construction and
ownership settings, not Stream tuning.

Exactly one listener source is selected:

  Linux::Event::IO::Sock::Listener->new(
      host => '0.0.0.0', port => 9999, stream => { ... },
  );

  Linux::Event::IO::Sock::Listener->new(
      unix => '/run/example.sock', stream => { ... },
  );

  Linux::Event::IO::Sock::Listener->new(
      fh => $existing_listener, stream => { ... },
  );

C<loop =E<gt> $loop> attaches immediately; otherwise add the detached Listener
with C<< $loop->add($listener) >>.

=head1 LISTENER CALLBACKS

C<on_accept> and C<on_error> at the top level belong to the Listener. Stream
C<on_error> belongs inside the C<stream> recipe.

  my $listener = Linux::Event::IO::Sock::Listener->new(
      host => '0.0.0.0',
      port => 9999,
      stream => {
          on_data => sub ($stream, $bytes) { ... },
          on_error => sub ($stream, $error) { ... },
      },
      on_accept => sub ($listener, $stream) { ... },
      on_error  => sub ($listener, $error)  { ... },
  );

A Listener subclass may define the same callback methods as reusable defaults.
Constructor callbacks override those methods for that Listener instance.

=head1 ACCEPTANCE

Native code drains C<accept4> with nonblocking and close-on-exec flags.
C<max_accept_per_tick> bounds level-triggered acceptance for fairness; zero
drains until C<EAGAIN> and is required with edge-triggered operation.

For every accepted socket Linux::Event constructs the resolved Stream class
with the already-prepared recipe descriptor, attaches it to the same Loop, and
then invokes optional C<on_accept($listener, $stream)>. A plain Stream's
C<on_ready> follows. For TLS, C<on_ready> waits for handshake and verification.

An C<on_accept> exception closes only that accepted connection and is reported
through the Listener C<on_error> callback.

=head1 TLS

TLS is generated-Stream acquisition policy and therefore belongs under
C<stream =E<gt> { tls =E<gt> {...} }>. A Stream class does not need to be a
special TLS subclass. TLS configuration is resolved when the Listener is
constructed and plain listeners allocate no OpenSSL connection state.

  my $listener = Linux::Event::IO::Sock::Listener->new(
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

The Listener prepares reusable server TLS context and policy once. Each accepted
TLS Stream receives independent connection state while sharing that prepared
server context. Ordinary server code does not need to load C<Linux::Event::TLS>
directly.

=head1 METHODS AND LIFECYCLE

C<port> reports the bound TCP port, including the kernel-selected value after
C<port =E<gt> 0>. C<family>, C<family_number>, C<is_tcp>, and C<is_unix>
identify the listening socket family.

C<pause> and C<resume> control acceptance while retaining the listening socket.
C<close> ends ownership. C<detach> returns the still-open listening handle and
is terminal. C<state> reports lifecycle such as C<unattached>, C<listening>,
C<paused>, C<closed>, C<failed>, or C<detached>.

Runtime errors are L<Linux::Event::Error> values. Resource exhaustion pauses
acceptance before error delivery to prevent a readable-backlog error spin.
