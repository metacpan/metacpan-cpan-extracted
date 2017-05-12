use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::GoogleMaps::MobileTool;

run {
    my $block       = shift;
    my ($lng,$lat,$zm)   = split(/\n/,$block->input);
    my ($tlng,$tlat)     = split(/\n/,$block->expected);

    my ( $dlng, $dlat )  = deltalnglat_perpixel( $lng, $lat, $zm );

    my ( $llng, $llat )  = deltapixel2lnglat( $lng, $lat,  1,  1, $zm );
    my ( $mlng, $mlat )  = deltapixel2lnglat( $lng, $lat, -1, -1, $zm );

    is ( sprintf( "%.6f", $dlng ), sprintf( "%.6f", abs( $llng - $mlng ) / 2 ) );
    is ( sprintf( "%.6f", $dlat ), sprintf( "%.6f", abs( $llat - $mlat ) / 2 ) );
};

__END__
===
--- input
-135.698608
35.757997
10
--- expected

===
--- input
135.698608
-35.757997
10
--- expected

===
--- input
-176.698608
84.757997
7
--- expected

===
--- input
176.698608
-84.757997
7
--- expected
