#!/usr/bin/perl
#
use v5.12;
use warnings;
use Test::More tests => 66;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color qw/color/;
use Graphics::Toolkit::Color::Space::Util ':all';

my $red = Graphics::Toolkit::Color->new('red');
my $blue = Graphics::Toolkit::Color->new('blue');

is( $blue->distance( $red ),            120, 'correct default hsl distance between red and blue');
is( $blue->distance( to => $red, in => 'HSL' ),     120, 'calling name space explicitly');
is( $blue->distance( to => $red, in => 'HSL', select => 'hsl'), 120, 'same in HASH syntax with full subspace');
is( $blue->distance( to => $red, in => 'HSL', select => 'HSL'), 120, 'same in list syntax with full subspace');
is( $blue->distance( to => $red, in => 'HSL', select => 'Hue'),  120, 'used only Hue subspace, long name');
is( $blue->distance( to => $red, in => 'HSL', select => 'h'),    120, 'used only Hue subspace, shortcut key');
is( $blue->distance( to => $red, in => 'HSL', select => 's'),       0, 'correct sturation distance between red and blue');
is( $blue->distance( to => $red, in => 'HSL', select => 'Saturation'), 0, 'correct sturation distance between red and blue, long name');
is( $blue->distance( to => $red, in => 'HSL', select => 'l'),          0, 'correct lightness distance between red and blue');
is( $blue->distance( to => $red, in => 'HSL', select => 'Lightness'),  0, 'correct lightness distance between red and blue, long name');
is( $blue->distance( to => $red, in => 'HSL', select => 'hs'),       120, 'correct hs distance between red and blue');
is( $blue->distance( to => $red, in => 'HSL', select => 'hl'),       120, 'correct hl distance between red and blue');
is( $blue->distance( to => $red, in => 'HSL', select => 'sl'),         0, 'correct sl distance between red and blue');
is( close_enough($blue->distance( to => $red, in => 'rgb'), 360.624458405 ), 1, 'correct rgb distance between red and blue');
is( $blue->distance( to => $red, in => 'rgb', select => 'Red'),     255, 'correct red distance between red and blue, long name');
is( $blue->distance( to => $red, in => 'rgb', select => 'r'),       255, 'correct red distance between red and blue');
is( $blue->distance( to => $red, in => 'rgb', select => 'Green'),     0, 'correct green distance between red and blue, long name');
is( $blue->distance( to => $red, in => 'rgb', select => 'g'),         0, 'correct green distance between red and blue');
is( $blue->distance( to => $red, in => 'rgb', select => 'Blue'),    255, 'correct blue distance between red and blue, long name');
is( $blue->distance( to => $red, in => 'rgb', select => 'b'),       255, 'correct blue distance between red and blue');
is( $blue->distance( to => $red, in => 'rgb', select => 'rg'),      255, 'correct rg distance between red and blue');
is( int $blue->distance( to => $red, in => 'rgb', select => 'rb'),  360, 'correct rb distance between red and blue');
is( $blue->distance(to => $red, in => 'rgb', select => 'gb'),      255, 'correct gb distance between red and blue');

is( int $blue->distance( to=> [10, 10, 245],      ),   7, 'correct default hsl  distance between own rgb blue and blue');
is( int $blue->distance( to=> [10, 10, 245], in => 'HSL'),   7, 'correct hsl distance between own rgb blue and blue');
is(     $blue->distance( to=> [10, 10, 245], in => 'HSL', select => 'Hue'),   0, 'correct hue distance between own rgb blue and blue, long name');
is(     $blue->distance( to=> [10, 10, 245], in => 'HSL', select => 'h'),     0, 'correct hue distance between own rgb blue and blue');
is( int $blue->distance( to=> [10, 10, 245], in => 'HSL', select => 's'),     7, 'correct sturation distance between own rgb blue and blue');
is( int $blue->distance( to=> [10, 10, 245], in => 'HSL', select => 'Saturation'),   7, 'correct sturation distance between own rgb blue and blue, long name');
is( int $blue->distance( to=> [10, 10, 245], in => 'HSL', select => 'l'),     0, 'correct lightness distance between own rgb blue and blue');
is( int $blue->distance( to=> [10, 10, 245], in => 'HSL', select => 'Lightness'), 0, 'correct lightness distance between own rgb blue and blue, long name');
is( int $blue->distance( to=> [10, 10, 245], in => 'HSL', select => 'hs'),    7, 'correct hs distance between own rgb blue and blue');
is( int $blue->distance( to=> [10, 10, 245], in => 'HSL', select => 'hl'),    0, 'correct hl distance between own rgb blue and blue');
is( int $blue->distance( to=> [10, 10, 245], in => 'HSL', select => 'sl'),    7, 'correct sl distance between own rgb blue and blue');
is( int $blue->distance( to=> [10, 10, 245], in => 'rgb'),  17, 'correct rgb distance between own rgb blue and blue');
is( close_enough( $blue->distance( to=> [10, 10, 245], in => 'rgb', select => 'Red'),  10), 1, 'correct red distance between own rgb blue and blue, long name');
is( close_enough( $blue->distance( to=> [10, 10, 245], in => 'rgb', select => 'r'),    10), 1, 'correct red distance between own rgb blue and blue');
is( close_enough( $blue->distance( to=> [10, 10, 245], in => 'rgb', select => 'Green'),10), 1, 'correct green distance between own rgb blue and blue, long name');
is( close_enough( $blue->distance( to=> [10, 10, 245], in => 'rgb', select => 'g'),    10), 1, 'correct green distance between own rgb blue and blue');
is( close_enough( $blue->distance( to=> [10, 10, 245], in => 'rgb', select => 'Blue'), 10), 1, 'correct blue distance between own rgb blue and blue, long name');
is( close_enough( $blue->distance( to=> [10, 10, 245], in => 'rgb', select => 'b'),    10), 1, 'correct blue distance between own rgb blue and blue');
is( int $blue->distance( to => [10, 10, 245], in => 'rgb', select => 'rg'),   14, 'correct rg distance between own rgb blue and blue');
is( int $blue->distance( to => [10, 10, 245], in => 'rgb', select => 'rb'),   14, 'correct rb distance between own rgb blue and blue');
is( int $blue->distance( to => [10, 10, 245], in => 'rgb', select => 'gb'),   14, 'correct gb distance between own rgb blue and blue');

is( int $blue->distance( to => {h =>230, s => 90, l=>40}),                17, 'correct default hsl distance between own hsl blue and blue');
is( int $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'HSL'),         17, 'correct hsl distance between own hsl blue and blue');
is(     $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'HSL', select => 'Hue'),  10, 'correct hue distance between own hsl blue and blue, long name');
is(     $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'HSL', select => 'h'),    10, 'correct hue distance between own hsl blue and blue');
is(     $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'HSL', select => 's'),    10, 'correct sturation distance between own hsl blue and blue');
is(     $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'HSL', select => 'Saturation'),  10, 'correct sturation distance between own hsl blue and blue, long name');
is(     $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'HSL', select => 'l'),    10, 'correct lightness distance between own hsl blue and blue');
is(     $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'HSL', select => 'Lightness'),10, 'correct lightness distance between own hsl blue and blue, long name');
is( int $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'HSL', select => 'hs'),   14, 'correct hs distance between own hsl blue and blue');
is( int $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'HSL', select => 'hl'),   14, 'correct hl distance between own hsl blue and blue');
is( int $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'HSL', select => 'sl'),   14, 'correct sl distance between own hsl blue and blue');
is( int $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'rgb'),         74, 'correct rgb distance between own hsl blue and blue');
is( int $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'RGB', select => 'Red'),  10, 'correct red distance between own hsl blue and blue, long name');
is( int $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'RGB', select => 'r'),    10, 'correct red distance between own hsl blue and blue');
is( round( $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'RGB', select => 'Green')),41, 'correct green distance between own hsl blue and blue, long name');
is( round( $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'RGB', select => 'g')),    41, 'correct green distance between own hsl blue and blue');
is( round( $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'RGB', select => 'Blue')), 61, 'correct blue distance between own hsl blue and blue, long name');
is( int $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'RGB', select => 'b'),    61, 'correct blue distance between own hsl blue and blue');
is( int $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'RGB', select => 'rg'),   42, 'correct rg distance between own hsl blue and blue');
is( int $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'RGB', select => 'rb'),   62, 'correct rb distance between own hsl blue and blue');
is( int $blue->distance( to => {h =>230, s => 90, l=>40}, in => 'RGB', select => 'gb'),   73, 'correct gb distance between own hsl blue and blue');

is( close_enough( $blue->distance(to => {h =>230, s => 0, l=>100}, in => 'CMYK' ), sqrt(2)),   1, 'measure distance between RGB ans HSL in CMYK');


exit 0;
