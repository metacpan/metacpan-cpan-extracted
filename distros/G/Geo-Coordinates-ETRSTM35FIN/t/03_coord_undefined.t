use strict;
use warnings;

use Test::More tests => 25;
BEGIN { use_ok('Geo::Coordinates::ETRSTM35FIN') };

my $gce = new Geo::Coordinates::ETRSTM35FIN;

# Tests for undefined coordinates. Defined coordinates are tested in 02_coordinates.t

#   [ Coordinate description, WGS84 Lat, WGS84 Lon ]
#       WGS84 Lat, WGS84 Lon,
#       ETRS-TM35FIN Lat, ETRS-TM35FIN Lon
#   ]

my @wgs84_out_of_bounds = (
	[ 'Too norhwest', "58.300", "18.000" ],
	[ 'Too west', "58.300", "20.000" ],
	[ 'Too south', "32.000", "60.000" ],
	[ 'Too southeast', "72.000", "32.000" ]
);

#   [ Coordinate description, ETRS-TM35FIN x, ETRS-TM35FIN y ]

my @etrs_out_of_bounds = (
	[ 'Too northwest', "6000000", "49000" ],
	[ 'Too west', "6000000", "52000" ],
	[ 'Too south', "7800000", "700000" ],
	[ 'Too southeast', "7800000", "800000" ]
);

foreach my $this_wgs84 ( @wgs84_out_of_bounds ) {
	my ($etrs_x, $etrs_y) = $gce->WGS84lalo_to_ETRSTM35FINxy($this_wgs84->[1], $this_wgs84->[2]);
	ok( !defined $etrs_x, "X: ".$this_wgs84->[0] );
	ok( !defined $etrs_y, "Y: ".$this_wgs84->[0] );
	
	ok( !defined $gce->is_defined_WGS84lalo($this_wgs84->[1], $this_wgs84->[2]), $this_wgs84->[0] );
}

foreach my $this_etrs ( @etrs_out_of_bounds ) {
	my ( $wgs_la, $wgs_lo ) = $gce->ETRSTM35FINxy_to_WGS84lalo($this_etrs->[1], $this_etrs->[2]);
	ok( !defined $wgs_la, "La: ".$this_etrs->[0] );
	ok( !defined $wgs_lo, "Lo: ".$this_etrs->[0] );
	
	ok( !defined $gce->is_defined_ETRSTM35FINxy($this_etrs->[1], $this_etrs->[2]), $this_etrs->[0] );
}

