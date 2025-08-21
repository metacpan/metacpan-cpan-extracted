#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 21;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Values;

########################################################################
my $darkblue = Graphics::Toolkit::Color::Values->new_from_any_input(['HSL', 240, 50, 25])->normalized;
my $red = Graphics::Toolkit::Color::Values->new_from_any_input(     ['HSL',   0, 50, 25])->normalized;
my $light_red = Graphics::Toolkit::Color::Values->new_from_any_input( ['HSL', 0, 50, 75])->normalized;
my $black = Graphics::Toolkit::Color::Values->new_from_any_input('black')->normalized;
my $white = Graphics::Toolkit::Color::Values->new_from_any_input('white')->normalized;
my $fuchsia = Graphics::Toolkit::Color::Values->new_from_any_input('fuchsia')->normalized;

my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');

my $distance      = \&Graphics::Toolkit::Color::Space::Hub::distance;
# @c1 @c2 -- ~space ~select @range --> +

is( $distance->( $darkblue, $darkblue, $RGB ),    0,   'dark blue should have no distance to itself');
is( int $distance->( $black, $white, 'RGB' ),    441,  'black and white have maximal distance in RGB');
is( $distance->( $fuchsia, $black, $RGB, undef, 'normal' ), sqrt 2,  'measure distance between magenta and black in RGB');
is( $distance->( $fuchsia, $black, $RGB, 'red', 'normal' ),      1,  'measure only red component');
is( $distance->( $black, $fuchsia, $RGB, 'red', 'normal' ),      1,  'order of args does not matter');
is( $distance->( $fuchsia, $black, $RGB, 'green', 'normal' ),    0,  'measure only green component');
is( $distance->( $fuchsia, $black, $RGB, 'blue', 'normal' ),     1,  'measure only blue component');
is( $distance->( $fuchsia, $black, $RGB, 'blue', 'normal' ),     1,  'measure only blue component');
is( $distance->( $fuchsia, $black, $RGB, [qw/r g/], 'normal' ),  1,  'measurered red and green component');
is( $distance->( $fuchsia, $black, $RGB, [qw/r b/], 'normal' ),  sqrt 2,  'measurered red and blue component');
is( $distance->( $fuchsia, $black, $RGB, 'blue', [8,9,10] ),    10,  'measure blue component woith custom scaling');

is( $distance->( $black, $white, $HSL ),               100,  'black and white have maximal distance in HSL');
is( $distance->( $black, $white, $HSL, 'l',  ),        100,  'only on the lightness axis');
is( $distance->( $black, $white, $HSL, 'h',  ),          0,  'not on the  saturation axis');
is( $distance->( $black, $white, $HSL, 's',  ),          0,  'or hue');
is( $distance->( $black, $white, $HSL, 'l', 'normal' ),  1,  'maximal distance in HSL, nrmalized');

is( $distance->( $darkblue, $red, $HSL,     ),         120,  'properly handle zylindrical dimension "hue" in HSL');
is( $distance->( $darkblue, $red, $HSL, undef, [3,2,2]), 1,  'same with custom range');
is( $distance->( $darkblue, $light_red, $HSL, undef, [3,2,2]), sqrt 2,  'two dimensional distance in "HSL"');
is( $distance->( $darkblue, $light_red, $HSL, 'lightness', [3,2,2]), 1,  '"lightness" part is one');
is( $distance->( $darkblue, $light_red, $HSL, ['h','l'], [3,2,2]), sqrt 2,  'select only axis that affect the difference');


exit 0;
