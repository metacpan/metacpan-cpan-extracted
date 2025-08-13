#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 20;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Values;

########################################################################
my $darkblue = Graphics::Toolkit::Color::Values->new_from_any_input(['HSL', 240, 50, 25]);
my $red = Graphics::Toolkit::Color::Values->new_from_any_input(     ['HSL',   0, 50, 25]);
my $light_red = Graphics::Toolkit::Color::Values->new_from_any_input( ['HSL', 0, 50, 75]);
my $black = Graphics::Toolkit::Color::Values->new_from_any_input('black');
my $white = Graphics::Toolkit::Color::Values->new_from_any_input('white');
my $fuchsia = Graphics::Toolkit::Color::Values->new_from_any_input('fuchsia');

my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');


is( $darkblue->distance( $darkblue, $RGB ),    0,   'dark blue should have no distance to itself');
is( int $black->distance( $white, $RGB ),    441,  'black and white have maximal distance in RGB');
is( $fuchsia->distance( $black, $RGB, undef, 'normal' ), sqrt 2,  'measure distance between magenta and black in RGB');
is( $fuchsia->distance( $black, $RGB, 'red', 'normal' ),      1,  'measure only red component');
is( $fuchsia->distance( $black, $RGB, 'green', 'normal' ),    0,  'measure only green component');
is( $fuchsia->distance( $black, $RGB, 'blue', 'normal' ),     1,  'measure only blue component');
is( $fuchsia->distance( $black, $RGB, 'blue', 'normal' ),     1,  'measure only blue component');
is( $fuchsia->distance( $black, $RGB, [qw/r g/], 'normal' ),  1,  'measurered red and green component');
is( $fuchsia->distance( $black, $RGB, [qw/r b/], 'normal' ),  sqrt 2,  'measurered red and blue component');
is( $fuchsia->distance( $black, $RGB, 'blue', [8,9,10] ),    10,  'measure blue component woith custom scaling');

is( $black->distance( $white, $HSL ),               100,  'black and white have maximal distance in HSL');
is( $black->distance( $white, $HSL, 'l',  ),        100,  'only on the lightness axis');
is( $black->distance( $white, $HSL, 'h',  ),          0,  'not on the  saturation axis');
is( $black->distance( $white, $HSL, 's',  ),          0,  'or hue');
is( $black->distance( $white, $HSL, 'l', 'normal' ),  1,  'maximal distance in HSL, nrmalized');
is( $darkblue->distance( $red, $HSL,     ),         120,  'properly handle zylindrical dimension "hue" in HSL');
is( $darkblue->distance( $red, $HSL, undef, [3,2,2]), 1,  'same with custom range');
is( $darkblue->distance( $light_red, $HSL, undef, [3,2,2]), sqrt 2,  'two dimensional distance in "HSL"');
is( $darkblue->distance( $light_red, $HSL, 'lightness', [3,2,2]), 1,  '"lightness" part is one');
is( $darkblue->distance( $light_red, $HSL, ['h','l'], [3,2,2]), sqrt 2,  'select only axis that affect the difference');


exit 0;
