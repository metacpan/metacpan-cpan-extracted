use strict;
use warnings;

use Test::More tests => 63;
BEGIN { use_ok('Geo::Coordinates::KKJ') };

#   [ Address,
#       WGS84 Lat, WGS84 Lon,
#       KKJx basic coordinate system, KKJy basic coordinate system,
#       KKJ Geo Lat, KKJ Geo Lon
#   ]
#
#   Coordinates can be checked from
#   http://kansalaisen.karttapaikka.fi/koordinaatit/koordinaatit.html?e=406643&n=7195132&scale=8000000&tool=siirra&lang=en
#
#

my @addresses = (
    [ "Konalantie 2, Helsinki",
        "60.22543759",  "24.85437044",
        "6679636.140", "2547526.214",
        "60.22526709", "24.85753425"
    ],
    [ "Ruusulankatu 10, Helsinki",
        "60.18234278", "24.92383647",
        "6674886.828", "2551442.967",
        "60.1821721", "24.92699227"
    ],
    [ "Mannerheimintie 1, Helsinki",
        "60.16809617", "24.94160776",
        "6673313.562", "2552451.703",
        "60.16792557", "24.94476112"
    ],
    [ "Taitoniekantie 9, Jyväskylä",
        "62.24764203", "25.71181796",
        "6905328.600", "3433223.575",
        "62.24736799", "25.71517274"
    ],
    [ "Albertinkatu 5, Oulu",
        "65.01067449", "25.46652827",
        "7213473.191", "2569333.429",
        "65.01029051", "25.47028481"
    ],
    [ "Porvoon sisäkehä 2, Porvoo",
        "60.41055121", "25.67922109",
        "6700675.972", "3427387.897",
        "60.41035052", "25.68236258"
    ],
);

foreach my $address ( @addresses ) {
    my ( $lat, $lon ) = KKJxy_to_KKJlalo($address->[3], $address->[4]);
    my $lat_diff = abs($lat - $address->[5]);
    my $lon_diff = abs($lon - $address->[6]);
    cmp_ok($lat_diff, "<=", 0.01);
    cmp_ok($lon_diff, "<=", 0.01);

    my ( $latw, $lonw ) = KKJlalo_to_WGS84lalo($address->[5], $address->[6]);
    my $latw_diff = abs($latw - $address->[1]);
    my $lonw_diff = abs($lonw - $address->[2]);
    cmp_ok($latw_diff, "<=", 0.01);
    cmp_ok($lonw_diff, "<=", 0.01);

    my ( $wlat, $wlon ) = KKJxy_to_WGS84lalo($address->[3], $address->[4]);
    my $wlat_diff = abs($wlat - $address->[1]);
    my $wlon_diff = abs($wlon - $address->[2]);
    cmp_ok($wlat_diff, "<=", 0.01);
    cmp_ok($wlon_diff, "<=", 0.01);

    my ( $kkj_lat, $kkj_lon ) = WGS84lalo_to_KKJlalo($address->[1], $address->[2]);
    my $kkj_lat_diff = abs($kkj_lat - $address->[5]);
    my $kkj_lon_diff = abs($kkj_lon - $address->[6]);
    cmp_ok($kkj_lat_diff, "<=", 0.01);
    cmp_ok($kkj_lon_diff, "<=", 0.01);

    my ( $kkj_lat2, $kkj_lon2 ) = WGS84lalo_to_KKJxy($address->[1], $address->[2]);
    my $kkj_lat_diff2 = abs($kkj_lat2 - $address->[3]);
    my $kkj_lon_diff2 = abs($kkj_lon2 - $address->[4]);
    cmp_ok($kkj_lat_diff2, "<=", 0.5);
    cmp_ok($kkj_lon_diff2, "<=", 0.5);
}

is(2, KKJ_Zone_Lo(24.853707887286728));
is(4, KKJ_Zone_Lo(28.853707887286728));
