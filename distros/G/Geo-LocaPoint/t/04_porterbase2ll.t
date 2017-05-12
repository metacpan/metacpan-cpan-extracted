use strict;
use Test::Base;
plan tests => 2 * blocks;

use Geo::LocaPoint qw(locaporterbase2latlng);

run {
    my $block = shift;
    my ($locapo)           = split(/\n/,$block->input);
    my ($lat,$lng)         = split(/\n/,$block->expected);

    my ($dlat,$dlng)       = locaporterbase2latlng($locapo);
    is $lat, $dlat;
    is $lng, $dlng;
};

__END__
===
--- input
SDHGFFxcatti
--- expected
35.606954
139.567104

===
--- input
SDHGFxcatt
--- expected
35.606934
139.567041

===
--- input
SDHGxcat
--- expected
35.606737
139.565544

===
--- input
SDHxca
--- expected
35.600592
139.526628

===
--- input
JBCAZHitfxch
--- expected
-27.371768
-58.798831

===
--- input
JBCAZitfxc
--- expected
-27.371796
-58.798886

===
--- input
JBCAitfx
--- expected
-27.372781
-58.799044

===
--- input
JBCitf
--- expected
-27.372781
-58.846153
