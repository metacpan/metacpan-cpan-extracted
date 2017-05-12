use strict;
use Test::Base;
use utf8;
plan tests => 2 * blocks;

use Geo::iArea;

run {
    my $block = shift;
    my ($lat,$lng)         = grep { $_ } split(/\n/,$block->input);
    my ($tcode,$tname)     = split(/\n/,$block->expected);

    my $ia = Geo::iArea->new($lat,$lng);

    if ( $ia ) {
        is $tcode,$ia->code;
        is $tname,$ia->name;
    } else {
        is $tcode,'UNDEF';
        is $tname,'UNDEF';
    }
};

__END__
===
--- input
35.000000
135.000000
--- expected
18201
北播磨

===
--- input
35.682660
139.767616
--- expected
05700
東京駅周辺

===
--- input
37.343371
138.828059
--- expected
04000
長岡

===
--- input
52354000000

--- expected
18201
北播磨

===
--- input
25100

--- expected
25100
宮古/石垣

===
--- input
20.000000
155.000000
--- expected
UNDEF
UNDEF

===
--- input
20000000123

--- expected
UNDEF
UNDEF

===
--- input
45207

--- expected
UNDEF
UNDEF

