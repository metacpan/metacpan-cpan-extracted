use strict;
use warnings;

use Test::More tests => 43;
BEGIN { use_ok('Geo::Coordinates::ETRSTM35FIN') };

my $gce = new Geo::Coordinates::ETRSTM35FIN;

# Tests for coordinate conversions and inbound coordinate detection. Undefined
# coordinates (out of bounds) are tested in 03_coord_undefined.t

#   [ Address,
#       WGS84 Lat, WGS84 Lon,
#       ETRS-TM35FIN x, ETRS-TM35FIN y
#   ]
#
#   Coordinates can be checked from
#   http://kansalaisen.karttapaikka.fi/koordinaatit/koordinaatit.html?e=406643&n=7195132&scale=8000000&tool=siirra&lang=en
#
#

my @addresses = (
    [ "Konalantie 2, Helsinki",
        "60.22543759",  "24.85437044",
        "6678450.000",	"381151.000"
    ],
    [ "Ruusulankatu 10, Helsinki",
        "60.18234278", "24.92383647",
        "6673529.000",	"384847.000"
    ],
    [ "Ratapihankatu 37, Turku",
        "60.45339438",	"22.25303183",
        "6711320.000",	"239010.000"
    ],
    [ "Taitoniekantie 9, Jyväskylä",
        "62.24764203", "25.71181796",
        "6902434.000",	"433080.000"
    ],
    [ "Albertinkatu 5, Oulu",
        "65.01014671", "25.46844702",
        "7210460.000",	"427810.000"
    ],
    [ "Koskikatu 1, Imatra",
        "61.1949885", "28.77741631",
        "6785805.000",	"595535.000"
    ],
    [ "Petsamontie 5, Inari",
    		"68.65976447", "27.54455398",
    		"7616523.000", "522115.000"
    ]
);

foreach my $address ( @addresses ) {
	# Coordinate conversions
    my ( $lat, $lon ) = $gce->ETRSTM35FINxy_to_WGS84lalo($address->[3], $address->[4]);
    my $lat_diff = abs($lat - $address->[1]);
    my $lon_diff = abs($lon - $address->[2]);
    cmp_ok($lat_diff, "<=", 0.01);
    cmp_ok($lon_diff, "<=", 0.01);

    my ( $latw, $lonw ) = $gce->WGS84lalo_to_ETRSTM35FINxy($address->[1], $address->[2]);
    my $latw_diff = abs($latw - $address->[3]);
    my $lonw_diff = abs($lonw - $address->[4]);
    cmp_ok($latw_diff, "<=", 0.01);
    cmp_ok($lonw_diff, "<=", 0.01);

	# Coordinates are in defined areas
	
	cmp_ok($gce->is_defined_ETRSTM35FINxy($address->[3], $address->[4]), "==", 1);
	cmp_ok($gce->is_defined_WGS84lalo($address->[1], $address->[2]), "==", 1);
}

