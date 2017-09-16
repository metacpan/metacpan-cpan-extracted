#!/usr/bin/perl -T
# Yes, we want to make sure things work in taint mode

#
# Copyright (C) 2016 J. Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;
use autodie;

use Carp;
use Test::More;
use Test::Exception;

use List::Util qw(none);

# Instantiate the object
require_ok('IP::Random');

# Make sure in_ipv4_subnet works
ok(IP::Random::in_ipv4_subnet('127.0.0.0/8', '127.0.0.0'), "127.0.0.0/8 includes 127.0.0.0");
ok(IP::Random::in_ipv4_subnet('127.0.0.0/8', '127.0.0.1'), "127.0.0.0/8 includes 127.0.0.1");
ok(IP::Random::in_ipv4_subnet('127.0.0.0/8', '127.255.255.0'), "127.0.0.0/8 includes 127.255.255.0");
ok(IP::Random::in_ipv4_subnet('127.0.0.0/8', '127.255.255.255'), "127.0.0.0/8 includes 127.255.255.255");
ok(! IP::Random::in_ipv4_subnet('127.0.0.0/32', '127.0.0.1'), "127.0.0.0/32 does not include 127.0.0.1");
ok(! IP::Random::in_ipv4_subnet('127.0.0.0/8', '0.0.0.0'), "127.0.0.0/8 does not include 0.0.0.0");
ok(! IP::Random::in_ipv4_subnet('127.0.0.0/8', '10.0.0.1'), "127.0.0.0/8 does not include 10.0.0.1");

my $sr = time;
diag("random seed: $sr");
srand($sr);

# Test form with no options
my @ip;
for (1..1000) {
    push @ip, IP::Random::random_ipv4();
}

my $count = 0;
my (@excludes) = ( '127.0.0.0/8', '224.0.0.0/4', '240.0.0.0/4', '192.168.0.0/16', '172.16.0.0/12' );

subtest "Large Test" => sub {
    foreach my $i (@ip) {
        ok((none { IP::Random::in_ipv4_subnet($_, $i) } @excludes), "Not using reserved IPs");
        if ($i ne $ip[0]) { $count++; }
    }
};

ok($count > 900, "IPs appear reasonably random");

# Exclude all IP addresses except 189.x.x.x
push @excludes, '0.0.0.0/1', '192.0.0.0/2';
push @excludes, '128.0.0.0/3', '160.0.0.0/4', '176.0.0.0/5', '184.0.0.0/6';
push @excludes, '188.0.0.0/8', '190.0.0.0/7';

my $ip = IP::Random::random_ipv4(
    exclude => \@excludes,
);
ok($ip =~ m/\A189\./, 'IP starts with 189 when using exclude');

$ip = IP::Random::random_ipv4(
    additional_exclude => \@excludes,
);
ok($ip =~ m/\A189\./, 'IP starts with 189 when using additional_exclude');

$ip = IP::Random::random_ipv4(
    exclude => [],
    additional_exclude => \@excludes,
);
ok($ip =~ m/\A189\./, 'IP starts with 189 when using exclude none and additional_exclude');

my $notrand = sub { my ($max, $oct) = @_; return $oct };
$ip = IP::Random::random_ipv4( rand => $notrand);
is($ip, '1.2.3.4', 'Validate custom random function called');

# Exclude all IP addresses except 0.0.0.0/8
@excludes = ();
push @excludes, '0.0.0.0/5', '8.0.0.0/7', '11.0.0.0/8', '12.0.0.0/6';
push @excludes, '16.0.0.0/4', '32.0.0.0/3', '64.0.0.0/2', '128.0.0.0/1';

$ip = IP::Random::random_ipv4(
    additional_types_allowed => [ 'rfc1918' ],
    additional_exclude => \@excludes,
);
ok($ip =~ m/\A10\./, 'IP starts with 10 when using rfc1918');

$ip = IP::Random::random_ipv4(
    additional_types_allowed => [ 'rfc1122', 'rfc1918' ],
    additional_exclude => \@excludes,
);
ok($ip =~ m/\A10\./, 'IP starts with 10 when using rfc1122 and rfc1918');

# All but 0.x.x.x & 10.x.x.x
@excludes = ();
push @excludes, '1.0.0.0/8', '2.0.0.0/7', '4.0.0.0/6', '8.0.0.0/7';
push @excludes, '11.0.0.0/8', '12.0.0.0/6';
push @excludes, '16.0.0.0/4', '32.0.0.0/3', '64.0.0.0/2', '128.0.0.0/1';
$ip = IP::Random::random_ipv4(
    additional_types_allowed => [ 'rfc1122' ],
    additional_exclude => \@excludes,
);
ok($ip =~ m/\A0\./, 'IP starts with 0 when using rfc1122 and rfc1918');

done_testing;

