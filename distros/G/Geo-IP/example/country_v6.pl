#!/usr/bin/perl

use Geo::IP;

my $gi
    = Geo::IP->open( "/usr/local/share/GeoIP/GeoIPv6.dat", GEOIP_STANDARD );

die "Please install the CAPI for IPv6 support\n" unless $gi->api eq 'CAPI';

while (<DATA>) {
    chomp;
    my ($cc) = $gi->country_code_by_addr_v6($_) || '';
    print join( "\t", $_, $cc ) . "\n";
}

__DATA__
::24.24.24.24
2001:4860:0:1001::68
2002:1818:1818::
2001:638:500:101:2e0:81ff:fe24:37c6
