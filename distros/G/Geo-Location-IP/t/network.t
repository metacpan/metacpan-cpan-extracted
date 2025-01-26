#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Network;

my $ipv4 = new_ok 'Geo::Location::IP::Network' =>
    [address => '172.31.17.1', prefixlen => 23];
is $ipv4, $ipv4, 'overloaded eq works';
can_ok $ipv4, qw(network_address prefixlen version with_prefixlen);
is $ipv4->network_address, '172.31.16.0',
    'IPv4 network address is "172.31.16.0"';
cmp_ok $ipv4->prefixlen, '==', 23, 'IPv4 prefix length is 23';
cmp_ok $ipv4->version,   '==', 4,  'IP version is 4';
is $ipv4, '172.31.16.0/23', 'IPv4 CIDR address is "172.31.16.0/23"';

my $negative_prefix
    = new_ok 'Geo::Location::IP::Network' =>
    [address => '127.0.0.0', prefixlen => -1];
ok !defined $negative_prefix->network_address, 'negative prefix length';

my $invalid_ipv4_prefix
    = new_ok 'Geo::Location::IP::Network' =>
    [address => '127.0.0.0', prefixlen => 33];
ok !defined $invalid_ipv4_prefix->network_address,
    'IPv4 prefix length is too big';

my $invalid_ipv4_address = new_ok 'Geo::Location::IP::Network' =>
    [address => '127.0.0.256', prefixlen => 32];
ok !defined $invalid_ipv4_address->with_prefixlen, 'invalid IPv4 address';

SKIP:
{
    skip 'IPv6 tests on Windows', 9 if $^O eq 'MSWin32';

    my $ipv6 = new_ok 'Geo::Location::IP::Network' =>
        [address => 'fdab:cdef::1', prefixlen => 23];
    like $ipv6->network_address, qr{^fdab:cc00:}i,
        'IPv6 network address is "fdab:cc00::"';
    cmp_ok $ipv6->prefixlen, '==', 23, 'IPv6 prefix length is 23';
    cmp_ok $ipv6->version,   '==', 6,  'IP version is 6';
    like $ipv6->with_prefixlen, qr{^fdab:cc00:[^/]+/23$}i,
        'IPv6 CIDR address is "fdab:cc00::/23"';

    my $invalid_ipv6_prefix = new_ok 'Geo::Location::IP::Network' =>
        [address => '::1', prefixlen => 129];
    ok !defined $invalid_ipv6_prefix->network_address,
        'IPv6 prefix length is too big';

    my $invalid_ipv6_address = new_ok 'Geo::Location::IP::Network' =>
        [address => 'fffff::', prefixlen => 128];
    ok !defined $invalid_ipv6_address->with_prefixlen, 'invalid IPv6 address';
}

done_testing;
