use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::GoogleMaps::MobileTool;
eval "use Geo::Proj;";

SKIP:{
    skip "Geo::Proj is not installed", 2 * blocks if($@);

    run {
        my $block       = shift;
        my ($x,$y,$zm)   = split(/\n/,$block->input);
        my ($tlng,$tlat) = split(/\n/,$block->expected);

        my ($lng,$lat) = pixel2lnglat( $x, $y, $zm );

        is ( sprintf( "%.6f", $lng ), $tlng );
        is ( sprintf( "%.6f", $lat ), $tlat );
    };
}

__END__
===
--- input
0
0
0
--- expected
-179.296875
84.990100

===
--- input
255
255
0
--- expected
179.296875
-84.990100

===
--- input
300
300
7
--- expected
-176.698608
84.757997

===
--- input
32467
32467
7
--- expected
176.698608
-84.757997

