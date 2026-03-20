package IO::K8s::Types::Net;
# ABSTRACT: Type::Tiny constraints for IP addresses and CIDR notation
our $VERSION = '1.009';
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

version 1.009

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/io-k8s-p5/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <torsten@raudssus.de>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
