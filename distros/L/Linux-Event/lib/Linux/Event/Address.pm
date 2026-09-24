package Linux::Event::Address;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.117';

use Socket qw(
    AF_INET AF_INET6 AF_UNIX
    inet_ntoa inet_ntop sockaddr_family
    unpack_sockaddr_in unpack_sockaddr_in6 unpack_sockaddr_un
);

sub new ($class, $sockaddr) {
    return bless {
        sockaddr => $sockaddr,
        parsed   => 0,
    }, $class;
}

sub sockaddr ($self) { $self->{sockaddr} }

sub _parse ($self) {
    return if $self->{parsed}++;
    my $packed = $self->{sockaddr};
    my $family = eval { sockaddr_family($packed) };
    $self->{family_number} = $family;

    if (defined($family) && $family == AF_INET) {
        my ($port, $address) = unpack_sockaddr_in($packed);
        $self->{family} = 'inet';
        $self->{host} = inet_ntoa($address);
        $self->{port} = $port;
        return;
    }
    if (defined($family) && $family == AF_INET6) {
        my ($port, $address, $scope_id, $flowinfo)
            = unpack_sockaddr_in6($packed);
        $self->{family} = 'inet6';
        $self->{host} = inet_ntop(AF_INET6, $address);
        $self->{port} = $port;
        $self->{scope_id} = $scope_id;
        $self->{flowinfo} = $flowinfo;
        return;
    }
    if (defined($family) && $family == AF_UNIX) {
        $self->{family} = 'unix';
        $self->{path} = eval { unpack_sockaddr_un($packed) };
        return;
    }
    $self->{family} = 'unknown';
    return;
}

sub family ($self)        { $self->_parse; $self->{family} }
sub family_number ($self) { $self->_parse; $self->{family_number} }
sub host ($self)          { $self->_parse; $self->{host} }
sub port ($self)          { $self->_parse; $self->{port} }
sub path ($self)          { $self->_parse; $self->{path} }
sub scope_id ($self)      { $self->_parse; $self->{scope_id} }
sub flowinfo ($self)      { $self->_parse; $self->{flowinfo} }

1;

__END__

=head1 NAME

Linux::Event::Address - Represent a socket address

=head1 SYNOPSIS

  sub show_peer ($stream) {
      my $peer = $stream->peer;

      if ($peer && $peer->family eq 'inet') {
          say $peer->host . ':' . $peer->port;
      }
  }

=head1 DESCRIPTION

C<Linux::Event::Address> represents a socket address returned or used by
Linux::Event networking objects.

It can describe:

=over 4

=item *

IPv4 addresses

=item *

IPv6 addresses

=item *

Unix-domain socket addresses

=back

For example, a TCP peer might be represented as:

  family: inet
  host:   127.0.0.1
  port:   8080

while a Unix-domain peer might instead have:

  family: unix
  path:   /tmp/example.sock

Applications normally receive Address objects from Linux::Event socket APIs
rather than constructing them manually.

=head1 ADDRESS FAMILIES

=head2 IPv4

For an IPv4 address:

  if ($address->family eq 'inet') {
      say $address->host;
      say $address->port;
  }

C<host> returns the numeric IPv4 address, such as:

  127.0.0.1

No DNS lookup is performed.

=head2 IPv6

For an IPv6 address:

  if ($address->family eq 'inet6') {
      say $address->host;
      say $address->port;
  }

C<host> returns the numeric IPv6 representation.

IPv6-specific C<scope_id> and C<flowinfo> values are also available.

=head2 Unix-domain sockets

For a Unix-domain address:

  if ($address->family eq 'unix') {
      say $address->path;
  }

C<path> returns the Unix socket path when one is available from the packed
address.

=head1 USING AN ADDRESS FROM A STREAM

A connected Stream can expose its peer address:

  my $peer = $stream->peer;

  if ($peer) {
      if ($peer->family eq 'inet' || $peer->family eq 'inet6') {
          say "peer: " . $peer->host . ':' . $peer->port;
      }
      elsif ($peer->family eq 'unix') {
          say "peer: " . $peer->path;
      }
  }

The same Address type is used throughout Linux::Event rather than returning a
different Perl class for every socket family.

=head1 DATAGRAM PEERS

Datagram receive callbacks also use Address values for sender addresses.

For example:

  on_datagram => sub ($self, $payload, $peer) {
      if ($peer->family eq 'inet') {
          say "received from " . $peer->host . ':' . $peer->port;
      }
  }

This gives the application both the datagram payload and the address from which
it arrived.

=head1 FAMILY

=head2 family

  my $family = $address->family;

Return a simple Linux::Event family name.

Possible values are:

=over 4

=item C<inet>

IPv4.

=item C<inet6>

IPv6.

=item C<unix>

Unix-domain socket.

=item C<unknown>

The packed address does not represent one of the families understood by this
class.

=back

This is usually the easiest method to use when deciding which other accessors
apply.

=head1 FAMILY NUMBER

=head2 family_number

  my $family = $address->family_number;

Return the numeric socket address-family value contained in the packed address.

For example, this may correspond to C<AF_INET>, C<AF_INET6>, or C<AF_UNIX>.

Most applications should prefer C<family> unless they specifically need the
native numeric family.

=head1 HOST

=head2 host

  my $host = $address->host;

For an IPv4 or IPv6 address, return the numeric host address.

For example:

  192.0.2.10

or:

  2001:db8::1

C<host> does not perform DNS resolution or reverse lookup.

For an address family where a host does not apply, it returns C<undef>.

=head1 PORT

=head2 port

  my $port = $address->port;

For IPv4 and IPv6 addresses, return the numeric port.

For example:

  443

For address families without a port, such as ordinary Unix-domain addresses,
it returns C<undef>.

=head1 UNIX SOCKET PATH

=head2 path

  my $path = $address->path;

For a Unix-domain socket address, return the path supplied by the kernel when
it can be decoded.

For Internet socket addresses, C<path> returns C<undef>.

=head1 IPV6 SCOPE ID

=head2 scope_id

  my $scope = $address->scope_id;

Return the IPv6 scope ID.

This value is primarily relevant to scoped IPv6 addresses such as link-local
addresses.

For non-IPv6 addresses, it returns C<undef>.

=head1 IPV6 FLOW INFORMATION

=head2 flowinfo

  my $flowinfo = $address->flowinfo;

Return the IPv6 flow-information field from the socket address.

Most applications will not need this value.

For non-IPv6 addresses, it returns C<undef>.

=head1 PACKED SOCKET ADDRESS

=head2 sockaddr

  my $packed = $address->sockaddr;

Return the original packed socket address.

Linux::Event retains this value exactly as the Address object's underlying
representation.

This method is useful when application code needs to pass the native packed
address to another socket API.

Most ordinary Linux::Event applications do not need to inspect it directly.

=head1 CONSTRUCTING AN ADDRESS DIRECTLY

Although Address objects are normally supplied by Linux::Event, an application
with an already-packed socket address may construct one directly:

  my $address = Linux::Event::Address->new($packed_sockaddr);

For example:

  use Socket qw(inet_aton pack_sockaddr_in);

  my $packed = pack_sockaddr_in(
      8080,
      inet_aton('127.0.0.1'),
  );

  my $address = Linux::Event::Address->new($packed);

  say $address->family;
  say $address->host;
  say $address->port;

This constructor expects a packed socket address, not a hostname and port pair.

Linux::Event's higher-level Stream, Listener, and Datagram APIs provide the
normal configuration interfaces for creating sockets.

=head1 LAZY DECODING

Address deliberately keeps the original packed socket address.

It does not immediately convert it into textual host, port, path, and IPv6
fields when the object is created.

Those values are decoded the first time one of the parsed accessors is needed:

  family
  family_number
  host
  port
  path
  scope_id
  flowinfo

The result is then retained by the Address object.

This matters because networking code often receives peer addresses that the
application never examines.

For example, a high-throughput server might accept thousands of connections
without ever needing to print every remote IP address.

In that case Linux::Event avoids unnecessary address-to-text conversion.

=head1 ACCESSORS THAT DO NOT APPLY

Address uses one common object for IPv4, IPv6, and Unix-domain addresses.

Therefore some methods naturally do not apply to every family.

For example:

  $unix_address->port

returns C<undef>, and:

  $ipv4_address->path

returns C<undef>.

Applications can use C<family> first when they need to know which values are
meaningful.

=head1 VALUE OBJECT

Address has no public setters.

It represents the socket address captured when the object was created.

Calling accessors does not perform another socket operation and does not ask the
kernel for a newer address.

=head1 PERFORMANCE MODEL

Stream, Listener, and Datagram code can create an Address directly from the
packed C<sockaddr> already returned by Linux socket operations.

The packed representation is retained until textual fields are actually
requested.

Applications that never inspect an address therefore avoid address formatting
work entirely.

=head1 SEE ALSO

L<Linux::Event>,
L<Linux::Event::IO::Sock::Stream>,
L<Linux::Event::IO::Sock::Listener>,
L<Linux::Event::IO::Sock::Dgram>.

=cut
