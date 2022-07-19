#!/usr/bin/env perl

use strict;
use warnings;

use Linux::WireGuard;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use Socket;

# Test::More uses Data::Dumper underneath.
use Data::Dumper;
$Data::Dumper::Useqq = 1;

my @names = Linux::WireGuard::list_device_names();

cmp_deeply(
    \@names,
    array_each( re( qr<.> ) ),
    'list_device_names()',
);

note explain \@names;

SKIP: {
    skip 'get_device() requires root' if $>;

    my @devices = map { Linux::WireGuard::get_device($_) } @names;

    my $uint_re = re( qr<\A[0-9]+\z> );
    my $optional_uint_re = any( undef, $uint_re );
    my $optional_str = any( undef, re( qr<.> ) );

    my $ipv4_addr_len = length pack_sockaddr_in(0, "\0" x 4);
    my $ipv6_addr_len = length pack_sockaddr_in6(0, "\0" x 16);

    cmp_deeply(
        \@devices,
        array_each( {
            name => re( qr<.> ),
            ifindex => $uint_re,
            public_key => $optional_str,
            private_key => $optional_str,
            fwmark => ignore(),
            listen_port => $optional_uint_re,
            peers => array_each( {
                public_key => $optional_str,
                preshared_key => $optional_str,
                endpoint => any(
                    undef,
                    re( qr<\A.{$ipv4_addr_len}\z> ),
                    re( qr<\A.{$ipv6_addr_len}\z> ),
                ),
                rx_bytes => $uint_re,
                tx_bytes => $uint_re,
                persistent_keepalive_interval => $optional_uint_re,
                last_handshake_time_sec => $uint_re,
                last_handshake_time_nsec => $uint_re,
                allowed_ips => array_each( {
                    family => any( Socket::AF_INET, Socket::AF_INET6 ),
                    addr => re( qr<\A.{4}|.{16}\z> ),
                    cidr => $uint_re,
                } ),
            } ),
        } ),
        'get_device()',
    ) or diag explain \@devices;

    note explain \@devices;
}

done_testing;
