#!/usr/local/bin/perl

use Geo::IP;

my $gi = Geo::IP->open(
    "/usr/local/share/GeoIP/GeoIPNetSpeedCell.dat",
    GEOIP_STANDARD
);

print $gi->name_by_addr("24.24.24.24"), $/;
