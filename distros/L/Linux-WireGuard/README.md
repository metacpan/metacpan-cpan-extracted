# NAME

Linux::WireGuard - [WireGuard](https://www.wireguard.com/) in Perl

# SYNOPSIS

    my @names = Linux::WireGuard::list_device_names();

    my %device = map { $_ => Linux::WireGuard::get_device($_) } @names;

# DESCRIPTION

Linux::WireGuard provides an interface to WireGuard via
[Linux’s embedded WireGuard C library](https://git.zx2c4.com/wireguard-tools/tree/contrib/embeddable-wg-library).

NB: Although WireGuard itself is cross-platform, its embedded C
library is Linux-specific.

# CHARACTER ENCODING

All strings into & out of this module are byte strings.

# ERROR HANDLING

Failures become Perl exceptions. Currently those exceptions are
plain strings. Errors that come from WireGuard also manifest as
changes to Perl’s `$!` global; for example, if you try to
`get_device()` while non-root, you’ll probably see (besides the
thrown exception) `$!` become Errno::EPERM.

# FUNCTIONS

## @names = list\_device\_names()

Returns a list of strings.

## $dev\_hr = get\_device( $NAME )

Returns a reference to a hash that describes the $NAME’d device:

- `name`
- `ifindex`
- `public_key` and `private_key` (raw strings, or undef)
- `fwmark` (can be undef)
- `listen_port` (can be undef)
- `peers` - reference to an array of hash references. Each hash is:
    - `public_key` and `preshared_key` (raw strings, or undef)
    - `endpoint` - Raw sockaddr data (a string), or undef. To parse
    the sockaddr, use [Socket](https://metacpan.org/pod/Socket)’s `sockaddr_family()` to determine the
    address family, then `unpack_sockaddr_in()` for Socket::AF\_INET or
    `unpack_sockaddr_in6()` for Socket::AF\_INET6.
    - `rx_bytes` and `tx_bytes`
    - `persistent_keepalive_interval` (can be undef)
    - `last_handshake_time_sec` and `last_handshake_time_nsec`
    - `allowed_ips` - reference to an array of hash references. Each hash is:
        - `family` - Socket::AF\_INET or Socket::AF\_INET6
        - `addr` - A packed IPv4 or IPv6 address. Unpack with [Socket](https://metacpan.org/pod/Socket)’s
        `inet_ntoa()` or `inet_ntop()`.
        - `cidr`

## add\_device( $NAME )

Adds a WireGuard device with the given $NAME.

## del\_device( $NAME )

Deletes a WireGuard device with the given $NAME.

## $bin = generate\_private\_key()

Returns a newly-generated private key (raw string).

## $bin = generate\_public\_key( $PRIVATE\_KEY )

Takes a private key and returns its public key. (Both raw strings.)

## $bin = generate\_preshared\_key()

Returns a newly-generated preshared key (raw string).

# TODO

An implementation of `set_device()` would be nice to have.

# LICENSE & COPYRIGHT

Copyright 2022 Gasper Software Consulting. All rights reserved.

Linux::WireGuard is licensed under the same terms as Perl itself (cf.
[perlartistic](https://metacpan.org/pod/perlartistic)); **HOWEVER**, the embedded C wireguard library has its
own copyright terms. Use of Linux::WireGuard _may_ imply acceptance of
that embedded C library’s own copyright terms. See this distribution’s
`wireguard-tools/contrib/embeddable-wg-library/README` for details.
