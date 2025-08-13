#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 74;
BEGIN { unshift @INC, 'lib', '../lib'}

my $module = 'Graphics::Toolkit::Color::Values';
use_ok( $module, 'could load the module');
my (@values, $values);
#### new_from_tuple ####################################################
is( ref Graphics::Toolkit::Color::Values->new_from_tuple(),  '',  'new need at least one argument');
my $fuchsia_rgb = Graphics::Toolkit::Color::Values->new_from_tuple([255,0,256], 'RGB');
is( ref $fuchsia_rgb,               $module,  'created values object from normalized RGB values');
is( $fuchsia_rgb->{'source_values'},     '',  'object source are RGB values');
is( $fuchsia_rgb->{'source_space_name'}, '',  'not from any other space');
is( $fuchsia_rgb->name,           'fuchsia',  'color has name "fuchsia"');
is( ref $fuchsia_rgb->{'rgb'},      'ARRAY',  'RGB tuple is an ARRAY');
is( @{$fuchsia_rgb->{'rgb'}},             3,  'RGB tuple has three values');
is( $fuchsia_rgb->{'rgb'}[0],             1,  'violet has a maximal red color');
is( $fuchsia_rgb->{'rgb'}[1],             0,  'violet has a no green color');
is( $fuchsia_rgb->{'rgb'}[2],             1,  'violet has a maximal blue color, got clamped');
$values = $fuchsia_rgb->normalized();
is( ref $values,                 'ARRAY',  'normalized value tuple is an ARRAY');
is( @$values,                          3,  'and has three values');
is( $values->[0],                      1,  'red value is as expected');
is( $values->[1],                      0,  'green value is as expected');
is( $values->[2],                      1,  'blue value is as expected');
is( $fuchsia_rgb->formatted('', 'named_string'),  'rgb: 255, 0, 255',  'got color formatted into named RGB string');
is( $fuchsia_rgb->formatted('CMY', 'CSS_string', undef, 10),  'cmy(0, 10, 0)',  'got color formatted into CMY CSS string');
$values = $fuchsia_rgb->formatted( '', 'ARRAY', undef, [20,30,40]);
is( ref $values,                 'ARRAY',  'RGB value ARRAY');
is( @$values,                          3,  'has three values');
is( $values->[0],                     20,  'red value is in hand crafted range');
is( $values->[1],                      0,  'green value is as expected');
is( $values->[2],                     40,  'blue value is in hand crafted range');
$values = $fuchsia_rgb->formatted( 'CMY', 'ARRAY', [20,30,40]);
is( ref $values,                   '',  'ARRAY format is only for RGB');

my $fuchsia_cmy = Graphics::Toolkit::Color::Values->new_from_tuple([0,1,0], 'CMY');
is( ref $fuchsia_cmy,                  $module,  'value object from CMY values');
is( ref $fuchsia_cmy->{'source_values'}, 'ARRAY',  'found source values');
is( int @{$fuchsia_cmy->{'source_values'}},    3,  'CMY has 3 axis');
is( $fuchsia_cmy->{'source_values'}[0],        0,  'cyan value is right');
is( $fuchsia_cmy->{'source_values'}[1],        1,  'magenta value is right');
is( $fuchsia_cmy->{'source_values'}[2],        0,  'yellow value is right');
is( $fuchsia_cmy->{'source_space_name'},   'CMY',  'cource space is correct');
is( $fuchsia_cmy->name,                'fuchsia',  'color has name "fuchsia"');
is( $fuchsia_cmy->{'rgb'}[0],                  1,  'violet(fuchsia) has a maximal red color');
is( $fuchsia_cmy->{'rgb'}[1],                  0,  'violet(fuchsia) has a no green color');
is( $fuchsia_cmy->{'rgb'}[2],                  1,  'violet(fuchsia) has a maximal blue color');
is( $fuchsia_cmy->formatted('RGB', 'hex_string'),  '#FF00FF',  'got color formatted into RGB hex string');
is( $fuchsia_cmy->formatted('XYZ', 'hex_string'),         '',  'HEX string is RGB only');

#### new_from_any_input ################################################
my $fuchsia_array = Graphics::Toolkit::Color::Values->new_from_any_input([255, 0, 256]);
is( ref $fuchsia_array,               $module,  'object from regular RGB tuple');
is( $fuchsia_array->{'source_values'},     '',  'object source are RGB values');
is( $fuchsia_array->{'source_space_name'}, '',  'not from any other space');
is( $fuchsia_array->name,           'fuchsia',  'color has name "fuchsia"');
is( $fuchsia_array->{'rgb'}[0],             1,  'violet has a maximal red color');
is( $fuchsia_array->{'rgb'}[1],             0,  'violet has a no green color');
is( $fuchsia_array->{'rgb'}[2],             1,  'violet has a maximal blue color, because it was clamped');

my $blue_hsl = Graphics::Toolkit::Color::Values->new_from_any_input({hue => 240, s => 100, l => 50});
is( ref $blue_hsl,                    $module,  'value object from HSL HASH');
is( ref $blue_hsl->{'source_values'}, 'ARRAY',  'found source values');
is( int @{$blue_hsl->{'source_values'}},    3,  'HSL has 3 axis');
is( $blue_hsl->{'source_values'}[0],      2/3,  'hue value is right');
is( $blue_hsl->{'source_values'}[1],        1,  'sat value is right');
is( $blue_hsl->{'source_values'}[2],      0.5,  'light value is right');
is( $blue_hsl->{'source_space_name'},   'HSL',  'cource space is correct');
is( $blue_hsl->name,                   'blue',  'color has name "blue"');
is( @{$blue_hsl->{'rgb'}},                  3,  'RGB tuple has three values');
is( $blue_hsl->{'rgb'}[0],                  0,  'blue has a no red vlaue');
is( $blue_hsl->{'rgb'}[1],                  0,  'blue has a no green value');
is( $blue_hsl->{'rgb'}[2],                  1,  'blue has a maximal blue value');

my $blue_hwb = Graphics::Toolkit::Color::Values->new_from_any_input('hwb( 240, 0%, 0% )');
is( ref   $blue_hwb,                    $module,  'value object from HWB named string');
is( ref   $blue_hwb->{'source_values'}, 'ARRAY',  'found source values');
is( int @{$blue_hwb->{'source_values'}},    3,  'HSL has 3 axis');
is( $blue_hwb->{'source_values'}[0],      2/3,  'hue value is right');
is( $blue_hwb->{'source_values'}[1],        0,  'white value is right');
is( $blue_hwb->{'source_values'}[2],        0,  'black value is right');
is( $blue_hwb->{'source_space_name'},   'HWB',  'cource space is correct');
is( $blue_hwb->name,                   'blue',  'color has name "blue"');
is( @{$blue_hwb->{'rgb'}},                  3,  'RGB tuple has three values');
is( $blue_hwb->{'rgb'}[0],                  0,  'blue has a no red vlaue');
is( $blue_hwb->{'rgb'}[1],                  0,  'blue has a no green value');
is( $blue_hwb->{'rgb'}[2],                  1,  'blue has a maximal blue value');

#### name and closest name #############################################
my $black = Graphics::Toolkit::Color::Values->new_from_any_input('ciexyz( 0, 0, 0)');
is( $black->name,                   'black',  'created black from CSS string in XYZ');
my $white = Graphics::Toolkit::Color::Values->new_from_any_input(['hsv', 0, 0, 100 ]);
is( $white->name,                   'white',  'created white from named ARRAY in HSV');

my ($hname, $hd) = $blue_hwb->closest_name_and_distance(2);
is( $hname,                 'blue',  'closest name to "blue" is the same as name');
is( $hd,                         0,  'no distance to closest name');
my ($cname, $cd) = $fuchsia_cmy->closest_name_and_distance(2);
is( $cname,                 'fuchsia',  'closest name to "fuchsia" is same as name');
is( $cd,                            0,  'no distance to closest name');

exit 0;
