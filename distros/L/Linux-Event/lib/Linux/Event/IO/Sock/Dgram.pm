package Linux::Event::IO::Sock::Dgram;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.115';

use parent 'Linux::Event::_Socket::Dgram';

1;

__END__

=head1 NAME

Linux::Event::IO::Sock::Dgram - asynchronous Linux C<SOCK_DGRAM> I/O

=head1 SYNOPSIS

  use v5.36;
  use Linux::Event::Loop;
  use Linux::Event::IO::Sock::Dgram;

  my $loop = Linux::Event::Loop->new;
  my $server = Linux::Event::IO::Sock::Dgram->new(
      loop => $loop,
      host => '127.0.0.1',
      port => 9999,
      on_datagram => sub ($socket, $payload, $peer) {
          $socket->send($payload, to => $peer);
      },
  );
  $loop->run;

=head1 DESCRIPTION

C<Linux::Event::IO::Sock::Dgram> is the public class for Linux C<SOCK_DGRAM>
sockets. It preserves kernel packet boundaries and peer addresses rather than
forcing datagrams through the ordered-byte framing engine.

UDP over IPv4 or IPv6 and Unix-domain datagram sockets use the same class;
address family is constructor policy rather than a public type hierarchy.

=head1 CALLBACKS, SUBCLASSING, AND TUNING

C<new> and C<connect> accept C<on_datagram>, C<on_ready>, C<on_drain>,
C<on_error>, and C<on_close> as constructor coderefs. Closures are convenient
for one socket and can capture lexical application state.

Subclassing remains valuable when sockets share packet policy, tuning, and
named callbacks. C<datagram_options> centralizes packet limits, fairness, queue
watermarks, and socket policy. C<configure_socket> is the cached subclass hook
for uncommon Linux socket configuration. Constructor values and callbacks
override class policy for one object. Linux::Event resolves all of this at
construction rather than looking up methods during packet delivery.

Datagrams already have kernel packet boundaries, so byte-stream framers and TLS
policy do not apply to this class.

=head2 datagram_options

Define C<datagram_options> as a class method on the Dgram subclass. It returns
key/value pairs, or one hash reference:

  package ServiceDgram;
  use parent 'Linux::Event::IO::Sock::Dgram';

  sub datagram_options ($class) {
      return (
          max_datagram_size      => 32_768,
          max_datagrams_per_tick => 128,
          receive_buffer         => 1_048_576,
      );
  }

  sub on_datagram ($socket, $payload, $peer) { ... }

Constructor values override this cached class policy for one socket. The
complete option set is:

=over 4

=item * C<max_datagram_size> (default 65,535)

Largest accepted packet, from 1 through 16,777,216 bytes. An oversized packet
is rejected whole rather than delivered as a truncated prefix.

=item * C<max_datagrams_per_tick> (default 256)

Non-negative receive fairness limit. Zero drains until C<EAGAIN> and is
required when C<edge_triggered> is enabled.

=item * C<edge_triggered> (default 0)

Boolean C<0> or C<1> selecting edge-triggered receive readiness.

=item * C<high_watermark> (default 1,048,576)

Non-negative queued-payload byte level at which C<send> begins returning false
while still accepting the datagram.

=item * C<low_watermark> (default 262,144)

Non-negative queued-payload byte level at or below which C<on_drain> fires
after high-watermark backpressure. It must not exceed C<high_watermark>.

=item * C<max_pending_bytes> (default 0)

Hard non-negative queued-payload byte limit. Zero means unbounded.

=item * C<max_pending_datagrams> (default 0)

Hard non-negative queued-datagram count limit. Zero means unbounded.

=item * C<reuseaddr> (default 0)

Boolean C<0> or C<1> controlling C<SO_REUSEADDR>.

=item * C<reuseport> (default 0)

Boolean C<0> or C<1> controlling C<SO_REUSEPORT>.

=item * C<broadcast> (default 0)

Boolean C<0> or C<1> controlling C<SO_BROADCAST>.

=item * C<v6only> (default unspecified)

Optional boolean C<0> or C<1> controlling C<IPV6_V6ONLY> on IPv6 sockets.

=item * C<send_buffer> (default unspecified)

Optional positive integer requested C<SO_SNDBUF> size, at most 2,147,483,647.

=item * C<receive_buffer> (default unspecified)

Optional positive integer requested C<SO_RCVBUF> size, at most 2,147,483,647.

=back

C<bind_device>, Unix path ownership options, and C<owns_socket> are constructor
policy rather than C<datagram_options> keys. C<configure_socket> is the cached
hook for uncommon Linux socket configuration.

=head1 BOUND AND CONNECTED FORMS

C<new> creates or adopts an unconnected packet socket. For UDP:

  my $server = EchoDgram->new(
      host => '0.0.0.0',
      port => 9999,
  );

C<connect> installs a default peer:

  my $client = EchoDgram->connect(
      host => 'collector.example.com',
      port => 9000,
  );

Hostnames for connected UDP are resolved asynchronously. Numeric Internet
addresses and Unix paths bypass resolution. Unix-domain sockets use C<unix> for
the bound or peer path and may use C<local_unix> for a connected client's local
reply path.

An adopted C<fh> must be an IPv4, IPv6, or Unix datagram socket. Created handles
are owned by the object; adopted handles remain caller-owned unless
C<owns_socket> is true.

C<loop =E<gt> $loop> attaches immediately. Detached objects may be added later
with C<< $loop->add($socket) >>.

=head1 CALLBACKS

A subclass may define, or construction may receive:

  sub on_datagram ($socket, $payload, $peer) { ... }

Each callback represents exactly one kernel datagram. C<$peer> is a lazy
L<Linux::Event::Address>. Zero-length datagrams are valid.

Optional C<on_ready>, C<on_drain>, C<on_error>, and C<on_close> callbacks cover
lifecycle and output flow control. Datagram I/O errors and queue-limit errors do
not automatically invent byte-stream EOF semantics.

=head1 SENDING

For a connected socket:

  $socket->send($payload);

For an unconnected socket:

  $socket->send($payload, to => $peer);

One C<send> call is one packet. If output would block, the complete datagram is
queued and retried atomically. High/low byte watermarks provide cooperative
backpressure. C<max_pending_bytes> and C<max_pending_datagrams> provide hard
queue bounds without splitting an accepted packet.

=head1 INPUT LIMITS AND FAIRNESS

C<max_datagram_size> bounds accepted packet size. Native C<recvmsg> uses
C<MSG_TRUNC> so an oversized packet can be rejected whole instead of delivering
a misleading prefix. C<max_datagrams_per_tick> bounds level-triggered receive
work for fairness; zero drains to C<EAGAIN> and is required for edge-triggered
operation.

=head1 SOCKET POLICY

C<datagram_options> caches packet limits, watermarks, fairness, and common
socket policy per subclass. Its complete contract appears near the top of this
document. Unix path ownership, permissions, and interface binding remain
per-object constructor policy.

=head1 METHODS AND LIFECYCLE

C<local> and C<peer> expose lazy address values where meaningful.
C<is_connected>, C<state>, C<pending_bytes>, and related queue accessors expose
current state.

C<close> terminates the object and releases owned socket/path resources.
C<detach> returns the still-open handle, suppresses Unix path removal, and is a
terminal ownership transfer.

=head1 SEE ALSO

L<Linux::Event::IO::Sock::Stream>, L<Linux::Event::Address>,
F<docs/DGRAM-DESIGN.md>, F<docs/SOCKET-CONFIGURATION.md>.

=cut
