use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::Proj::Japan;
use Geo::Point;

run {
    my $block = shift;
    my ($fproj,$flat,$flng)         = split(/\n/,$block->input);
    my ($tproj,$tlat,$tlng)         = split(/\n/,$block->expected);

    my $pf = Geo::Point->latlong($flat, $flng, $fproj);
    my $pt = Geo::Proj->to($pf->proj, $tproj, [$pf->long, $pf->lat]);

    is sprintf("%.6f",$pt->[1]), $tlat;
    is sprintf("%.6f",$pt->[0]), $tlng;
};

__END__
===
--- input
wgs84
35.000000
135.000000
--- expected
tokyo
34.996802
135.002793

===
--- input
wgs84
35.000000
135.000000
--- expected
tokyo97
34.996802
135.002793

===
--- input
wgs84
35.000000
135.000000
--- expected
jgd2000
35.000000
135.000000

===
--- input
tokyo
35.000000
135.000000
--- expected
wgs84
35.003197
134.997208

===
--- input
tokyo97
35.000000
135.000000
--- expected
wgs84
35.003197
134.997208

===
--- input
jgd2000
35.000000
135.000000
--- expected
wgs84
35.000000
135.000000
