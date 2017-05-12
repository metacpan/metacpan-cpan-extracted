use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::GeoPo;

run {
    my $block = shift;
    my ($lat,$lng,$scl)   = split(/\n/,$block->input);
    my ($geopo)           = split(/\n/,$block->expected);

    is $geopo,                   latlng2geopo( $lat, $lng, $scl );
    is "http://geopo.at/$geopo", latlng2geopo( $lat, $lng, $scl, { as_url => 1 } );
};

__END__
===
--- input
35.658578
139.745447
6
--- expected
Z4RHXX

===
--- input
48.858271
2.294512
7
--- expected
C1qn6PM

===
--- input
-13.1637
-72.545777
6
--- expected
jr2QzI



