use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::LocaPoint;

run {
    my $block = shift;
    my ($locapo)           = split(/\n/,$block->input);
    my ($lat,$lng)         = split(/\n/,$block->expected);

    my ($dlat,$dlng)       = locapoint2latlng($locapo);
    is $lat, $dlat;
    is $lng, $dlng;
};

__END__
===
--- input
SD7.XC0.GF5.TT8
--- expected
35.606954
139.567104

===
--- input
JB2.IT5.AZ7.XC7
--- expected
-27.371768
-58.798831
