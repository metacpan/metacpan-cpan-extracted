#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.026;
use warnings;
use utf8;

use Test::More;

use Geo::Location::IP::Address;
use Geo::Location::IP::Network;

my $ipv4_network = new_ok 'Geo::Location::IP::Network' =>
    [address => '172.16.0.0', prefixlen => 16];

my $ipv4 = new_ok 'Geo::Location::IP::Address' =>
    [address => '172.16.0.1', network => $ipv4_network];
is $ipv4, $ipv4, 'overloaded eq works';
can_ok $ipv4, qw(address network version);
is $ipv4, '172.16.0.1', 'IPv4 address is "172.16.0.1"';
ok defined $ipv4->network, 'network is defined';
cmp_ok $ipv4->version, '==', 4, 'IP version is 4';

$ipv4 = Geo::Location::IP::Address->_from_hash({ip_address => '172.16.0.2'},
    $ipv4);
is $ipv4, '172.16.0.2', 'IPv4 address is "172.16.0.2"';
cmp_ok $ipv4->version, '==', 4, 'IP version is 4';

$ipv4 = Geo::Location::IP::Address->_from_hash({ip_address => '172.16.0.3'},
    undef);
is $ipv4, '172.16.0.3', 'IPv4 address is "172.16.0.3"';
cmp_ok $ipv4->version, '==', 4, 'IP version is 4';

$ipv4_network = new_ok 'Geo::Location::IP::Network' =>
    [address => undef, prefixlen => 0];

$ipv4 = new_ok 'Geo::Location::IP::Address' =>
    [address => '172.16.0.4', network => $ipv4_network];
is $ipv4, '172.16.0.4', 'IPv4 address is "172.16.0.4"';
cmp_ok $ipv4->version, '==', 4, 'IP version is 4';

$ipv4 = new_ok 'Geo::Location::IP::Address' =>
    [address => undef, network => undef];
ok !defined $ipv4->version, 'IP version is not defined';

SKIP:
{
    skip 'IPv6 tests on Windows', 5 if $^O eq 'MSWin32';

    my $ipv6_network = new_ok 'Geo::Location::IP::Network' =>
        [address => 'fdab:cdef::', prefixlen => 64];

    my $ipv6 = new_ok 'Geo::Location::IP::Address' =>
        [address => 'fdab:cdef::1', network => $ipv6_network];
    ok defined $ipv6->address, 'address is defined';
    ok defined $ipv6->network, 'network is defined';
    cmp_ok $ipv6->version, '==', 6, 'IP version is 6';
}

done_testing;
