package IP::Decimal;

use strict;
use warnings;
use Data::Validate::IP qw/
    is_ipv4
    is_ipv6
/;
use NetAddr::IP::Util qw/
    inet_aton
    inet_ntoa
    ipv6_aton
    ipv6_ntoa
/;
use Math::Int128 qw/
    net_to_uint128
    uint128_to_net
/;

use base qw/Exporter/;

our @EXPORT_OK = qw/
   ipv4_to_decimal
   decimal_to_ipv4
   ipv6_to_decimal
   decimal_to_ipv6
/;

our $VERSION = 0.02;

sub ipv4_to_decimal {
    my $ipv4 = shift;
    
    return unpack 'N', inet_aton($ipv4) if is_ipv4 $ipv4;
    return undef;
}

sub decimal_to_ipv4 {
    my $decimal = shift;
    
    my $ipv4 = join '.', inet_ntoa(pack 'N', $decimal);
    return $ipv4 if is_ipv4 $ipv4;
    return undef;
}

sub ipv6_to_decimal {
    my $ipv6 = shift;
    
    return net_to_uint128(ipv6_aton($ipv6)) if is_ipv6 $ipv6;
    return undef;
}

sub decimal_to_ipv6 {
    my $decimal = shift;
    
    my $ipv6 = ipv6_ntoa(uint128_to_net($decimal));
    return $ipv6 if is_ipv6 $ipv6;
    return undef;
}

1;

=encoding utf8

=head1 NAME

IP::Decimal - Convert IP to Decimal and Decimal to IP

=head1 SYNOPSIS

    use IP::Decimal qw/
        ipv4_to_decimal
        decimal_to_ipv4
        ipv6_to_decimal
        decimal_to_ipv6
    /;
    
    my $decimal = ipv4_to_decimal('127.0.0.1'); # 2130706433
    
    my $ipv4 = decimal_to_ipv4('2130706433'); # 127.0.0.1
    
=head1 DESCRIPTION
    
This module provides methods for convert IP to Decimal and Decimal to IP, simply and directly.

=head1 METHODS

=head2 ipv4_to_decimal

    my $decimal = ipv4_to_decimal('127.0.0.1');
    
Returns the decimal: 2130706433

=head2 decimal_to_ipv4

    my $ip = decimal_to_ipv4('2130706433');
    
Returns the IP 127.0.0.1

=head2 ipv6_to_decimal

    my $decimal = ipv6_to_decimal('dead:beef:cafe:babe::f0ad');
    
Returns the decimal: 295990755076957304698079185533545803949

=head2 decimal_to_ipv6

    my $ip = decimal_to_ipv6('295990755076957304698079185533545803949');
    
Returns the IP dead:beef:cafe:babe::f0ad

=head1 AUTHOR
 
Lucas Tiago de Moraes C<lucastiagodemoraes@gmail.com>
 
=head1 COPYRIGHT AND LICENSE
 
This software is copyright (c) 2020 by Lucas Tiago de Moraes.
 
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
 
=cut