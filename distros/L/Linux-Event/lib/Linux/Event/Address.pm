package Linux::Event::Address;
use v5.36;
use strict;
use warnings;

our $VERSION = '0.116';

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

Linux::Event::Address - lazy socket-address value

=head1 SYNOPSIS

  use v5.36;

  sub show_peer ($stream) {
      my $peer = $stream->peer;
      if ($peer && $peer->family eq 'inet') {
          say $peer->host . ':' . $peer->port;
      }
  }

=head1 DESCRIPTION

Represents a packed IPv4, IPv6, or Unix socket address.
L<Linux::Event::IO::Sock::Stream>, L<Linux::Event::IO::Sock::Listener>, and
L<Linux::Event::IO::Sock::Dgram> use it for peer and local addresses. The
packed sockaddr is retained without conversion; textual parsing occurs only
when an accessor is used. Accessors that do not apply to the address family
return undef.

=head1 METHODS

=head2 sockaddr

Return the original packed peer address.

=head2 family / family_number

Return C<inet>, C<inet6>, C<unix>, or C<unknown>, and the numeric address-family
constant.

=head2 host / port

Return Internet host and port details when applicable.

=head2 path

Return the Unix peer path when supplied by the kernel.

=head2 scope_id / flowinfo

Return IPv6 ancillary address fields.

=head1 PERFORMANCE

Stream listeners and datagram sockets create Address values directly from
packed sockaddrs returned by C<accept4> and C<recvmsg>. Applications that do not
inspect an address avoid address-to-text conversion entirely.

=cut
