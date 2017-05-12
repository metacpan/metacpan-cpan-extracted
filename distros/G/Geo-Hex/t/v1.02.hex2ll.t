use strict;
use Test::Base;
plan tests => 4 * blocks;
use Geo::Hex1;

run {
    my $block = shift;
    my ($hex)             = split(/\n/,$block->input);
    my ($lat,$lng,$level) = split(/\n/,$block->expected);

    my ($tlat, $tlng, $tlevel) = geohex2latlng($hex);
    is $lat,   sprintf('%.6f',$tlat);
    is $lng,   sprintf('%.6f',$tlng);
    is $level, $tlevel;

    is $hex, latlng2geohex($tlat,$tlng,$tlevel);
};

__END__
===
--- input
wkmP
--- expected
35.654108
139.700874
7

===
--- input
132KpwT
--- expected
35.658310
139.700877
1

===
--- input
ff96I
--- expected
35.652007
139.702372
15

===
--- input
rmox
--- expected
34.692665
135.501638
7

===
--- input
132bBGK
--- expected
34.691965
135.500138
1

===
--- input
fcaLw
--- expected
34.695465
135.495642
15

===
--- input
032dD
--- expected
34.726980
135.518158
60

===
--- input
032Lr
--- expected
35.652000
139.657388
60
