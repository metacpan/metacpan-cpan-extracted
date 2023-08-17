#!/usr/bin/perl
#
use v5.12;
use warnings;
use Test::More tests => 67;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color qw/color/;

my $red = Graphics::Toolkit::Color->new('red');
my $blue = Graphics::Toolkit::Color->new('blue');

is( $blue->distance( $red ),            120, 'correct default hsl distance between red and blue');
is( $blue->distance( $red, 'HSL' ),     120, 'calling name space explicitly');
is( $blue->distance({to => $red, in => 'HSL'}), 120, 'same in HASH syntax');
is( $blue->distance({to => $red, in => 'HSL', notice_only => 'hsl'}), 120, 'same in HASH syntax with full subspace');
is( $blue->distance( $red, 'HSL', 'HSL'), 120, 'same in list syntax with full subspace');
is( $blue->distance( $red, 'HSL', 'Hue'),  120, 'used only Hue subspace, long name');
is( $blue->distance( $red, 'HSL', 'h'),    120, 'used only Hue subspace, shortcut key');
is( $blue->distance( $red, 'HSL', 's'),       0, 'correct sturation distance between red and blue');
is( $blue->distance( $red, 'HSL', 'Saturation'), 0, 'correct sturation distance between red and blue, long name');
is( $blue->distance( $red, 'HSL', 'l'),          0, 'correct lightness distance between red and blue');
is( $blue->distance( $red, 'HSL', 'Lightness'),  0, 'correct lightness distance between red and blue, long name');
is( $blue->distance( $red, 'HSL', 'hs'),       120, 'correct hs distance between red and blue');
is( $blue->distance( $red, 'HSL', 'hl'),       120, 'correct hl distance between red and blue');
is( $blue->distance( $red, 'HSL', 'sl'),         0, 'correct sl distance between red and blue');
is( close_enough($blue->distance( $red, 'rgb'),360.624458405 ), 1, 'correct rgb distance between red and blue');
is( $blue->distance($red, 'rgb', 'Red'),     255, 'correct red distance between red and blue, long name');
is( $blue->distance($red, 'rgb', 'r'),       255, 'correct red distance between red and blue');
is( $blue->distance($red, 'rgb', 'Green'),     0, 'correct green distance between red and blue, long name');
is( $blue->distance($red, 'rgb', 'g'),         0, 'correct green distance between red and blue');
is( $blue->distance($red, 'rgb', 'Blue'),    255, 'correct blue distance between red and blue, long name');
is( $blue->distance($red, 'rgb', 'b'),       255, 'correct blue distance between red and blue');
is( $blue->distance($red, 'rgb', 'rg'),      255, 'correct rg distance between red and blue');
is( int $blue->distance($red, 'rgb', 'rb'),  360, 'correct rb distance between red and blue');
is( $blue->distance($red, 'rgb', 'gb'),      255, 'correct gb distance between red and blue');

is( int $blue->distance([10, 10, 245],      ),   8, 'correct default hsl  distance between own rgb blue and blue');
is( int $blue->distance([10, 10, 245], 'HSL'),   8, 'correct hsl distance between own rgb blue and blue');
is(     $blue->distance([10, 10, 245], 'HSL', 'Hue'),   0, 'correct hue distance between own rgb blue and blue, long name');
is(     $blue->distance([10, 10, 245], 'HSL', 'h'),     0, 'correct hue distance between own rgb blue and blue');
is( int $blue->distance([10, 10, 245], 'HSL', 's'),     8, 'correct sturation distance between own rgb blue and blue');
is( int $blue->distance([10, 10, 245], 'HSL', 'Saturation'),   8, 'correct sturation distance between own rgb blue and blue, long name');
is( int $blue->distance([10, 10, 245], 'HSL', 'l'),     0, 'correct lightness distance between own rgb blue and blue');
is( int $blue->distance([10, 10, 245], 'HSL', 'Lightness'), 0, 'correct lightness distance between own rgb blue and blue, long name');
is( int $blue->distance([10, 10, 245], 'HSL', 'hs'),    8, 'correct hs distance between own rgb blue and blue');
is( int $blue->distance([10, 10, 245], 'HSL', 'hl'),    0, 'correct hl distance between own rgb blue and blue');
is( int $blue->distance([10, 10, 245], 'HSL', 'sl'),    8, 'correct sl distance between own rgb blue and blue');
is( int $blue->distance([10, 10, 245], 'rgb'),  17, 'correct rgb distance between own rgb blue and blue');
is(     $blue->distance([10, 10, 245], 'rgb', 'Red'),  10, 'correct red distance between own rgb blue and blue, long name');
is(     $blue->distance([10, 10, 245], 'rgb', 'r'),    10, 'correct red distance between own rgb blue and blue');
is(     $blue->distance([10, 10, 245], 'rgb', 'Green'),10, 'correct green distance between own rgb blue and blue, long name');
is(     $blue->distance([10, 10, 245], 'rgb', 'g'),    10, 'correct green distance between own rgb blue and blue');
is(     $blue->distance([10, 10, 245], 'rgb', 'Blue'), 10, 'correct blue distance between own rgb blue and blue, long name');
is(     $blue->distance([10, 10, 245], 'rgb', 'b'),    10, 'correct blue distance between own rgb blue and blue');
is( int $blue->distance([10, 10, 245], 'rgb', 'rg'),   14, 'correct rg distance between own rgb blue and blue');
is( int $blue->distance([10, 10, 245], 'rgb', 'rb'),   14, 'correct rb distance between own rgb blue and blue');
is( int $blue->distance([10, 10, 245], 'rgb', 'gb'),   14, 'correct gb distance between own rgb blue and blue');

is( int $blue->distance({h =>230, s => 90, l=>40}),                17, 'correct default hsl distance between own hsl blue and blue');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'HSL'),         17, 'correct hsl distance between own hsl blue and blue');
is(     $blue->distance({h =>230, s => 90, l=>40}, 'HSL', 'Hue'),  10, 'correct hue distance between own hsl blue and blue, long name');
is(     $blue->distance({h =>230, s => 90, l=>40}, 'HSL', 'h'),    10, 'correct hue distance between own hsl blue and blue');
is(     $blue->distance({h =>230, s => 90, l=>40}, 'HSL', 's'),    10, 'correct sturation distance between own hsl blue and blue');
is(     $blue->distance({h =>230, s => 90, l=>40}, 'HSL', 'Saturation'),  10, 'correct sturation distance between own hsl blue and blue, long name');
is(     $blue->distance({h =>230, s => 90, l=>40}, 'HSL', 'l'),    10, 'correct lightness distance between own hsl blue and blue');
is(     $blue->distance({h =>230, s => 90, l=>40}, 'HSL', 'Lightness'),10, 'correct lightness distance between own hsl blue and blue, long name');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'HSL', 'hs'),   14, 'correct hs distance between own hsl blue and blue');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'HSL', 'hl'),   14, 'correct hl distance between own hsl blue and blue');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'HSL', 'sl'),   14, 'correct sl distance between own hsl blue and blue');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'rgb'),         74, 'correct rgb distance between own hsl blue and blue');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'RGB', 'Red'),  10, 'correct red distance between own hsl blue and blue, long name');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'RGB', 'r'),    10, 'correct red distance between own hsl blue and blue');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'RGB', 'Green'),40, 'correct green distance between own hsl blue and blue, long name');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'RGB', 'g'),    40, 'correct green distance between own hsl blue and blue');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'RGB', 'Blue'), 62, 'correct blue distance between own hsl blue and blue, long name');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'RGB', 'b'),    62, 'correct blue distance between own hsl blue and blue');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'RGB', 'rg'),   41, 'correct rg distance between own hsl blue and blue');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'RGB', 'rb'),   62, 'correct rb distance between own hsl blue and blue');
is( int $blue->distance({h =>230, s => 90, l=>40}, 'RGB', 'gb'),   73, 'correct gb distance between own hsl blue and blue');

is( close_enough( $blue->distance({h =>230, s => 0, l=>100}, 'CMYK' ), sqrt(2)),   1, 'measure distance between RGB ans HSL in CMYK');


sub close_enough {
    my ($nr, $target) = @_;
    abs($nr - $target) < 0.01
}

exit 0;
