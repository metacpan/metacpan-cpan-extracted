#!/usr/bin/perl

use Geo::IP;

my $gi
    = Geo::IP->open( "/usr/local/share/GeoIP/GeoIPCity.dat", GEOIP_STANDARD );

while (<DATA>) {
    chomp;
    my $r = $gi->record_by_name($_);
    if ($r) {
        print join(
            "\t",
            $r->country_code, $r->country_name, $r->city,
            $r->region,       $r->region_name,  $r->postal_code,
            $r->latitude,     $r->longitude,    $r->metro_code,
            $r->area_code
        ) . "\n";
    }
    else {
        print "UNDEF\n";
    }
}

__DATA__
12.10.1.4
0.0.0.0
66.108.94.158
yahoo.com
amazon.com
4.2.144.64
24.24.24.24
80.24.24.24
