use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::GoogleMaps::MobileTool qw(unableProj);

run {
    my $block       = shift;
    my ($lng,$lat,$zm)  = split(/\n/,$block->input);
    my ($tx,$ty)        = split(/\n/,$block->expected);

    my ($x,$y) = lnglat2pixel( $lng, $lat, $zm );

    is ( $x, $tx );
    is ( $y, $ty );
};

__END__
===
--- input
139.745493
35.658517
0
--- expected
227
100

===
--- input
-139.745493
-35.658517
0
--- expected
28
155

===
--- input
139.745493
35.658517
3
--- expected
1818
806

===
--- input
-139.745493
-35.658517
3
--- expected
229
1241





