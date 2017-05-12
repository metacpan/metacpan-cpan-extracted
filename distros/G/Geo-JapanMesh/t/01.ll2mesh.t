use strict;
use Test::Base;
plan tests => 6 * blocks;

use Geo::JapanMesh qw(:DEFAULT :iareamesh);

run {
    my $block = shift;
    my ($lat,$lng)         = split(/\n/,$block->input);
    my ($jmes,$imes)       = split(/\n/,$block->expected);

    my ( $mes3, $mes2, $mes1 ) = $jmes =~ /(((.+)\-.+)\-.+)/;
    my ( $mes8, $mes7, $mes6 ) = $imes =~ /(((\d{10})\d)\d)/;

    is $mes1, latlng2japanmesh($lat,$lng,1);
    is $mes2, latlng2japanmesh($lat,$lng,2);
    is $mes3, latlng2japanmesh($lat,$lng,3);
    is $mes6, latlng2iareamesh($lat,$lng,6);
    is $mes7, latlng2iareamesh($lat,$lng,7);
    is $mes8, latlng2iareamesh($lat,$lng,8);
};

__END__
===
--- input
37.10426013
139.30664063
--- expected
5539-52-24
553952031101

===
--- input
34.97240037
135.65917969
--- expected
5235-35-62
523535212021

===
--- input
32.00434921
130.91308594
--- expected
4830-07-03
483007010033

===
--- input
43.27400562
142.91015625
--- expected
6442-77-22
644277030030

===
--- input
35.691425
139.705556
--- expected
5339-45-26
533945121023
