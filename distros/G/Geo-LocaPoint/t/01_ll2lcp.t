use strict;
use Test::Base;
plan tests => 1 * blocks;

use Geo::LocaPoint;

run {
    my $block = shift;
    my ($lat,$lng)         = split(/\n/,$block->input);
    my ($locapo)           = split(/\n/,$block->expected);

    is $locapo, latlng2locapoint($lat,$lng);
};

__END__
===
--- input
35.606954
139.567104
--- expected
SD7.XC0.GF5.TT8

===
--- input
-27.371768
-58.798831
--- expected
JB2.IT5.AZ7.XC7
