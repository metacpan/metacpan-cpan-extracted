use strict;
use Test::Base;
plan tests => 1 * blocks;

use Geo::LocaPoint qw(latlng2locaporterbase);

run {
    my $block = shift;
    my ($lat,$lng,$prec)   = split(/\n/,$block->input);
    my ($locaporterbase)   = split(/\n/,$block->expected);

    is $locaporterbase, latlng2locaporterbase($lat,$lng,$prec);
};

__END__
===
--- input
35.606954
139.567104
6
--- expected
SDHGFFxcatti

===
--- input
35.606954
139.567104
5
--- expected
SDHGFxcatt

===
--- input
35.606954
139.567104
4
--- expected
SDHGxcat

===
--- input
35.606954
139.567104
3
--- expected
SDHxca

===
--- input
-27.371768
-58.798831
6
--- expected
JBCAZHitfxch

===
--- input
-27.371768
-58.798831
5
--- expected
JBCAZitfxc

===
--- input
-27.371768
-58.798831
4
--- expected
JBCAitfx

===
--- input
-27.371768
-58.798831
3
--- expected
JBCitf

