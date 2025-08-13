#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 52;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';
use Graphics::Toolkit::Color::Values;

my $module = 'Graphics::Toolkit::Color::Values';
my $blue = Graphics::Toolkit::Color::Values->new_from_any_input('blue');
my $black = Graphics::Toolkit::Color::Values->new_from_any_input('black');
my $white = Graphics::Toolkit::Color::Values->new_from_any_input('white');

my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');
my $HSL = Graphics::Toolkit::Color::Space::Hub::get_space('HSL');
my $HWB = Graphics::Toolkit::Color::Space::Hub::get_space('HWB');
my $LAB = Graphics::Toolkit::Color::Space::Hub::get_space('LAB');

#### set ###############################################################
my $aqua = $blue->set( {green => 255} );
is( ref $aqua,                   $module,  'aqua (set green value to max) value object');
is( $aqua->name,                  'aqua',  'color has the name "aqua"');
my $values = $aqua->normalized();
is( ref $values,                 'ARRAY',  'RGB value ARRAY');
is( @$values,                          3,  'has three values');
is( $values->[0],                      0,  'red value is zero');
is( $values->[1],                      1,  'green value is one (max)');
is( $values->[2],                      1,  'blue value is one too');
is( ref $blue->set( {green => 256}, 'CMY' ),  '',  'green is in RGB, not CMY');
is( ref $blue->set( {green => 256, yellow => 0},  ),  '',  'green and yellow axis are from different spaces');
$aqua = $blue->set( {green => 256}, 'RGB' );
$values = $aqua->normalized();
is( ref $aqua,                   $module,  'green is in RGB, and set green over max, got clamped');
is( @$values,                          3,  'has three values');
is( $values->[0],                      0,  'red value is zero');
is( $values->[1],                      1,  'green value is one (max)');
is( $values->[2],                      1,  'blue value is one too');

#### add ###############################################################
$aqua = $blue->add( {green => 255} );
is( ref $aqua,                   $module,  'aqua (add green value to max) value object');
is( $aqua->name,                  'aqua',  'color has the name "aqua"');
$values = $aqua->normalized();
is( ref $values,                 'ARRAY',  'RGB value ARRAY');
is( @$values,                          3,  'has three values');
is( $values->[0],                      0,  'red value is zero');
is( $values->[1],                      1,  'green value is one (max)');
is( $values->[2],                      1,  'blue value is one too');
is( ref $blue->add( {green => 256}, 'CMY' ),  '',  'green is in RGB, not CMY');
is( ref $blue->add( {green => 256, yellow => 0},  ),  '',  'green and yellow axis are from different spaces');
$aqua = $blue->add( {green => 256}, 'RGB' );
$values = $aqua->normalized();
is( ref $aqua,                   $module,  'green is in RGB, and set green over max, got clamped');
is( @$values,                          3,  'has three values');
is( $values->[0],                      0,  'red value is zero');
is( $values->[1],                      1,  'green value is one (max)');
is( $values->[2],                      1,  'blue value is one too');

#### mix ###############################################################
my $grey = $white->mix([{color => $black, percent => 50}], $RGB);
is( ref $grey,                   $module,  'created gray by mixing black and white');
$values = $grey->shaped();
is( @$values,                          3,  'get RGB values of grey');
is( $values->[0],                    128,  'red value of gray');
is( $values->[1],                    128,  'green value of gray');
is( $values->[2],                    128,  'blue value of gray');
is( $grey->name(),                'gray',  'created gray by mixing black and white');

my $lgrey = $white->mix([{color => $black, percent => 5}], $RGB);
is( ref $lgrey,                   $module,  'created light gray');
$values = $lgrey->shaped();
is( @$values,                          3,  'get RGB values of grey');
is( $values->[0],                    242,  'red value of gray');
is( $values->[1],                    242,  'green value of gray');
is( $values->[2],                    242,  'blue value of gray');
is( $lgrey->name(),             'gray95',  'created gray by mixing black and white');

my $darkblue = $white->mix([{color => $blue, percent => 60},{color => $black, percent => 60},], $HSL);
is( ref $darkblue,               $module,  'mixed black and blue in HSL, recalculated percentages from sum of 120%');
$values = $darkblue->shaped('HSL');
is( @$values,                          3,  'get 3 HSL values');
is( $values->[0],                    120,  'hue value is right');
is( $values->[1],                     50,  'sat value is right');
is( $values->[2],                     25,  'light value is right');

#### invert ############################################################
is( $white->invert($RGB)->name,             'black',  'black is white inverted');
is( $black->invert($RGB)->name,             'white',  'white is black inverted');
is( $blue->invert($RGB)->name,             'yellow',  'yellow is blue inverted');
is( $blue->invert($HSL)->name,               'gray',  'in HSL is gray opposite to any color');
is( $blue->invert($LAB)->name,                   '',  'LAB is not symmetrical');
is( $white->invert($HSL)->name,             'black',  'primary contrast works in HSL');
is( $white->invert($HWB)->name,             'black',  'primary contrast works in HWB');

exit 0;
