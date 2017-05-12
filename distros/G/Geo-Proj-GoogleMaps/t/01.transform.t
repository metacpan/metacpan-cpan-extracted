use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::Proj::GoogleMaps;
use Geo::Point;

run {
    my $block = shift;
    my ($fproj,$fx,$fy)         = split(/\n/,$block->input);
    my ($tproj,$tx,$ty)         = split(/\n/,$block->expected);

    my $pf = Geo::Point->xy($fx, $fy, $fproj);
    my $pt = Geo::Proj->to($pf->proj, $tproj, [$pf->x, $pf->y]);

    is sprintf("%.6f",$pt->[0]), $tx;
    is sprintf("%.6f",$pt->[1]), $ty;
};

__END__
===
--- input
wgs84
135.000000
35.000000
--- expected
google
15028131.257092
4163881.144064

===
--- input
google
15028131.26
4163881.14
--- expected
wgs84
135.000000
35.000000

===
--- input
wgs84
-145.000000
-20.000000
--- expected
google
-16141326.165025
-2273030.926988

===
--- input
google
-16141326.17
-2273030.93
--- expected
wgs84
-145.000000
-20.000000

