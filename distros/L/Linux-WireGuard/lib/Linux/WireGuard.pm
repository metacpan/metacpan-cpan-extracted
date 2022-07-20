package Linux::WireGuard;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Linux::WireGuard - L<WireGuard|https://www.wireguard.com/> in Perl

=head1 SYNOPSIS

    my @names = Linux::WireGuard::list_device_names();

    my %device = map { $_ => Linux::WireGuard::get_device($_) } @names;

=head1 DESCRIPTION

Linux::WireGuard provides an interface to WireGuard via
L<Linux’s embedded WireGuard C library|https://git.zx2c4.com/wireguard-tools/tree/contrib/embeddable-wg-library>.

NB: Although WireGuard itself is cross-platform, its embedded C
library is Linux-specific.

=head1 CHARACTER ENCODING

All strings into & out of this module are byte strings.

=head1 ERROR HANDLING

Failures become Perl exceptions. Currently those exceptions are
plain strings. Errors that come from WireGuard also manifest as
changes to Perl’s C<$!> global; for example, if you try to
C<get_device()> while non-root, you’ll probably see (besides the
thrown exception) C<$!> become Errno::EPERM.

=cut

#----------------------------------------------------------------------

use XSLoader;

our $VERSION = '0.03';

XSLoader::load( __PACKAGE__, $VERSION );

#----------------------------------------------------------------------

=head1 FUNCTIONS

=head2 @names = list_device_names()

Returns a list of strings.

=head2 $dev_hr = get_device( $NAME )

Returns a reference to a hash that describes the $NAME’d device:

=over

=item * C<name>

=item * C<ifindex>

=item * C<public_key> and C<private_key> (raw strings, or undef)

=item * C<fwmark> (can be undef)

=item * C<listen_port> (can be undef)

=item * C<peers> - reference to an array of hash references. Each hash is:

=over

=item * C<public_key> and C<preshared_key> (raw strings, or undef)

=item * C<endpoint> - Raw sockaddr data (a string), or undef. To parse
the sockaddr, use L<Socket>’s C<sockaddr_family()> to determine the
address family, then C<unpack_sockaddr_in()> for Socket::AF_INET or
C<unpack_sockaddr_in6()> for Socket::AF_INET6.

=item * C<rx_bytes> and C<tx_bytes>

=item * C<persistent_keepalive_interval> (can be undef)

=item * C<last_handshake_time_sec> and C<last_handshake_time_nsec>

=item * C<allowed_ips> - reference to an array of hash references. Each hash is:

=over

=item * C<family> - Socket::AF_INET or Socket::AF_INET6

=item * C<addr> - A packed IPv4 or IPv6 address. Unpack with L<Socket>’s
C<inet_ntoa()> or C<inet_ntop()>.

=item * C<cidr>

=back

=back

=back

=head2 add_device( $NAME )

Adds a WireGuard device with the given $NAME.

=head2 del_device( $NAME )

Deletes a WireGuard device with the given $NAME.

=head2 $bin = generate_private_key()

Returns a newly-generated private key (raw string).

=head2 $bin = generate_public_key( $PRIVATE_KEY )

Takes a private key and returns its public key. (Both raw strings.)

=head2 $bin = generate_preshared_key()

Returns a newly-generated preshared key (raw string).

=head1 TODO

An implementation of C<set_device()> would be nice to have.

=head1 LICENSE & COPYRIGHT

Copyright 2022 Gasper Software Consulting. All rights reserved.

Linux::WireGuard is licensed under the same terms as Perl itself (cf.
L<perlartistic>); B<HOWEVER>, the embedded C wireguard library has its
own copyright terms. Use of Linux::WireGuard I<may> imply acceptance of
that embedded C library’s own copyright terms. See this distribution’s
F<wireguard-tools/contrib/embeddable-wg-library/README> for details.

=cut

1;
