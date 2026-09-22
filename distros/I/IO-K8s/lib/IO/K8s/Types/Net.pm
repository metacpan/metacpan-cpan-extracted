package IO::K8s::Types::Net;
# ABSTRACT: Type::Tiny constraints for IP addresses and CIDR notation
our $VERSION = '1.108';
use v5.10;
use Type::Library -base, -declare => qw( IPv4 IPv6 IPAddress CIDR NetIP );
use Type::Utils -all;
use Types::Standard -types;
use Net::IP ();
use Exporter 'import';

our @EXPORT_OK = qw( parse_ip cidr_contains is_rfc1918 );


declare IPv4, as Str, where {
    !/\// && do { my $ip = Net::IP->new($_, 4); defined $ip && $ip->version == 4 };
}, message { "'$_' is not a valid IPv4 address" };


declare IPv6, as Str, where {
    !/\// && do { my $ip = Net::IP->new($_, 6); defined $ip && $ip->version == 6 };
}, message { "'$_' is not a valid IPv6 address" };


declare IPAddress, as Str, where {
    !/\// && defined Net::IP->new($_);
}, message { "'$_' is not a valid IP address" };


declare CIDR, as Str, where {
    /\// && defined Net::IP->new($_);
}, message { "'$_' is not valid CIDR notation" };


declare NetIP, as InstanceOf['Net::IP'];
coerce NetIP, from Str, via { Net::IP->new($_) };


sub parse_ip {
    my ($str) = @_;
    return Net::IP->new($str);
}


sub cidr_contains {
    my ($cidr_str, $ip_str) = @_;
    my $cidr = Net::IP->new($cidr_str) or return 0;
    my $ip   = Net::IP->new($ip_str)   or return 0;
    my $overlap = $ip->overlaps($cidr);
    return defined $overlap && ($overlap == $Net::IP::IP_A_IN_B_OVERLAP || $overlap == $Net::IP::IP_IDENTICAL);
}


sub is_rfc1918 {
    my ($ip_str) = @_;
    return cidr_contains('10.0.0.0/8', $ip_str)
        || cidr_contains('172.16.0.0/12', $ip_str)
        || cidr_contains('192.168.0.0/16', $ip_str);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::K8s::Types::Net - Type::Tiny constraints for IP addresses and CIDR notation

=head1 VERSION

version 1.108

=head1 SYNOPSIS

    use IO::K8s::Types::Net qw( IPv4 IPv6 IPAddress CIDR NetIP );
    use IO::K8s::Types::Net qw( parse_ip cidr_contains is_rfc1918 );

    IPAddress->check('10.0.0.1');       # type constraints
    my $ip = parse_ip('10.0.0.1');      # helper constructor
    cidr_contains('10.0.0.0/8', $ip);  # CIDR containment test
    is_rfc1918('192.168.1.1');          # RFC 1918 private-use test

=head1 DESCRIPTION

This module is a L<Type::Library> bundling L<Net::IP>-backed type
constraints and helpers for working with IPv4/IPv6 addresses and CIDR
ranges. It is the source of truth for IP / CIDR validation across
IO::K8s -- both the L<IO::K8s::Role::CertManaged> fluent builders and
the L<IO::K8s::Role::NetworkPolicy> CIDR checks run through these
constraints.

Five Type::Tiny types are declared:

=over

=item C<IPv4> -- single IPv4 addresses (no CIDR suffix).

=item C<IPv6> -- single IPv6 addresses (no CIDR suffix).

=item C<IPAddress> -- either IPv4 or IPv6, no CIDR suffix.

=item C<CIDR> -- CIDR-notation strings (the slash is mandatory).

=item C<NetIP> -- L<Net::IP> instances, with a coercion from plain
strings.

=back

Three helper functions are optionally exported:

=over

=item C<parse_ip> -- thin wrapper over C<< Net::IP->new >>.

=item C<cidr_contains> -- returns true iff an IP lies inside a CIDR.

=item C<is_rfc1918> -- true iff an IP lies inside one of the three
RFC 1918 private-use ranges.

=back

Each type and each function is documented under its own L<=func> block
below.

=head2 IPv4

    use IO::K8s::Types::Net qw( IPv4 );

    IPv4->check('10.0.0.1');   # 1
    IPv4->check('10.0.0.1/8'); # undef (no CIDR suffix)

A L<Type::Tiny> constraint accepting only strings that look like a single
IPv4 address (no CIDR suffix). Validated via L<Net::IP>; the constraint's
diagnostic message is C<< '$_' is not a valid IPv4 address >>.

=head2 IPv6

    use IO::K8s::Types::Net qw( IPv6 );

    IPv6->check('::1');      # 1
    IPv6->check('10.0.0.1'); # undef

A L<Type::Tiny> constraint accepting only single IPv6 addresses (no CIDR
suffix). Validated via L<Net::IP>. The diagnostic message is
C<< '$_' is not a valid IPv6 address >>.

=head2 IPAddress

    use IO::K8s::Types::Net qw( IPAddress );

    IPAddress->check('10.0.0.1');   # 1
    IPAddress->check('::1');        # 1
    IPAddress->check('10.0.0.0/8'); # undef (CIDR belongs in CIDR)

A L<Type::Tiny> constraint accepting either IPv4 or IPv6 single addresses
(no CIDR suffix). Validated via L<Net::IP> -- a value is good iff
C<Net::IP-E<gt>new($_)> constructs successfully. The diagnostic message is
C<< '$_' is not a valid IP address >>.

This is the type the L<IO::K8s::Role::CertManaged/add_ip_san> sanity-check
runs against; the role does the validation rather than installing the
attribute as an C<IPAddress> directly because Certificate CRDs accept
arrays of plain strings on the wire.

=head2 CIDR

    use IO::K8s::Types::Net qw( CIDR );

    CIDR->check('10.0.0.0/8'); # 1
    CIDR->check('10.0.0.1');   # undef (no slash)

A L<Type::Tiny> constraint accepting only CIDR-notation strings
(e.g. C<10.0.0.0/8>). The string must contain a C</>; L<Net::IP> then has
to parse the rest. The diagnostic message is
C<< '$_' is not valid CIDR notation >>.

=head2 NetIP

    use IO::K8s::Types::Net qw( NetIP );

    NetIP->check(Net::IP->new('10.0.0.1')); # 1

A L<Type::Tiny> constraint accepting only L<Net::IP> instances. Comes with
a coercion: any plain string is run through C<Net::IP-E<gt>new($_)>, so
attributes declared C<NetIP> can be constructed from a string. The
coercion does no validation -- L<Net::IP::Error> will tell you whether
the result is usable.

=head2 parse_ip

    my $ip = parse_ip('10.0.0.1');

Thin wrapper around C<< Net::IP->new($str) >>. Returns the L<Net::IP>
object on success, C<undef> on failure. Optional export from
L<IO::K8s::Types::Net>.

    if (my $ip = parse_ip($value)) {
        say "v", $ip->version;
    }

=head2 cidr_contains

    cidr_contains('10.0.0.0/8', '10.1.2.3'); # 1 (10.1.2.3 is in 10/8)
    cidr_contains('10.0.0.0/8', '11.0.0.1'); # 0

Returns a true value iff C<$ip_str> lies inside C<$cidr_str>. Both inputs
are run through L<Net::IP>; either one failing to parse returns C<0>
(rather than croaking) so the function is safe to call on untrusted
input. Optional export from L<IO::K8s::Types::Net>.

=head2 is_rfc1918

    is_rfc1918('192.168.1.1');    # 1
    is_rfc1918('10.0.0.1');       # 1
    is_rfc1918('172.16.5.5');     # 1
    is_rfc1918('8.8.8.8');        # 0

Returns a true value iff C<$ip_str> lies inside any of the three
RFC 1918 private-use ranges (C<10.0.0.0/8>, C<172.16.0.0/12>,
C<192.168.0.0/16>). Implemented in terms of C<cidr_contains>; an
unparseable input is treated as not-RFC1918. Optional export from
L<IO::K8s::Types::Net>.

=head1 SEE ALSO

L<Net::IP>, L<Type::Tiny>, L<IO::K8s::Role::CertManaged>,
L<IO::K8s::Role::NetworkPolicy>

=cut

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
