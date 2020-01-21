# NAME

IP::Decimal - Convert IP to Decimal and Decimal to IP

# SYNOPSIS

    use IP::Decimal qw/
        ipv4_to_decimal
        decimal_to_ipv4
        ipv6_to_decimal
        decimal_to_ipv6
    /;
    
    my $decimal = ipv4_to_decimal('127.0.0.1'); # 2130706433
    
    my $ipv4 = decimal_to_ipv4('2130706433'); # 127.0.0.1
    
# DESCRIPTION

This module provides methods for convert IP to Decimal and Decimal to IP, simply and directly.

# METHODS

## ipv4_to_decimal

    my $decimal = ipv4_to_decimal('127.0.0.1');
    
Returns the decimal: 2130706433

## decimal_to_ipv4

    my $ip = decimal_to_ipv4('2130706433');
    
Returns the IP 127.0.0.1

## ipv6_to_decimal

    my $decimal = ipv6_to_decimal('dead:beef:cafe:babe::f0ad');
    
Returns the decimal: 295990755076957304698079185533545803949

## decimal_to_ipv6

    my $ip = decimal_to_ipv6('295990755076957304698079185533545803949');
    
Returns the IP dead:beef:cafe:babe::f0ad

# AUTHOR

Lucas Tiago de Moraes `lucastiagodemoraes@gmail.com`

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Lucas Tiago de Moraes.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.