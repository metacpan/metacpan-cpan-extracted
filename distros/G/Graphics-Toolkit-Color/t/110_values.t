#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 36	;

my $module = 'Graphics::Toolkit::Color::Values';
eval "use $module"; # say $@;
is( not($@), 1, 'could load the module');

my (@values, $values);
my $RGB = Graphics::Toolkit::Color::Space::Hub::get_space('RGB');

#### new_from_tuple ####################################################
is( ref Graphics::Toolkit::Color::Values->new_from_tuple(),  '',  'new need at least one argument');
my $fuchsia_rgb = Graphics::Toolkit::Color::Values->new_from_tuple([255,0,255], 'RGB');
is( ref $fuchsia_rgb,               $module,  'created values object from normalized RGB values');
is( $fuchsia_rgb->{'source_tuple'},      '',  'object source are RGB values');
is( $fuchsia_rgb->{'source_space_name'}, '',  'not from any other space');
is( $fuchsia_rgb->name,           'magenta',  'color has name "magenta"');
is_tuple( $RGB->round($fuchsia_rgb->{'rgb_tuple'}, 7), [1, 0, 1], [qw/red green blue/], 'fuchsia got right core rgb values');

$values = $fuchsia_rgb->normalized();
is_tuple( $values, [1, 0, 1], [qw/red green blue/], 'normalized values default to RGB');
is( $fuchsia_rgb->formatted('', 'named_string'),  'rgb: 255, 0, 255',  'got color formatted into named RGB string');
is( $fuchsia_rgb->formatted('CMY', 'CSS_string', undef, 10),  'cmy(0, 10, 0)',  'got color formatted into CMY CSS string');
$values = $fuchsia_rgb->formatted( '', 'ARRAY', undef, [20,30,40]);
is_tuple( $values, [20, 0, 40], [qw/red green blue/], 'got values formatted into an ARRAY (custom ranges)');
$values = $fuchsia_rgb->formatted( 'CMY', 'ARRAY');
is_tuple( $values, [0, 1, 0], [qw/cyan magenta yellow/], 'ARRAY format can output for  any space');

my $fuchsia_cmy = Graphics::Toolkit::Color::Values->new_from_tuple([0,1,0], 'CMY');
is( ref $fuchsia_cmy,                    $module,  'value object from CMY values');
is_tuple( $RGB->round($fuchsia_cmy->{'source_tuple'}, 7), [0, 1, 0], [qw/cyan magenta yellow/], 'fuchsia got right source tuple');
is( $fuchsia_cmy->{'source_space_name'},   'CMY',  'cource space is correct');
is( $fuchsia_cmy->name,                'magenta',  'color has name "magenta"');
is_tuple( $RGB->round($fuchsia_cmy->{'rgb_tuple'}, 7), [1, 0, 1], [qw/red green blue/], 'fuchsia got right rgb tuple');
is( $fuchsia_cmy->formatted('RGB', 'hex_string'),  '#FF00FF',  'got color formatted into RGB hex string');
is( $fuchsia_cmy->formatted('XYZ', 'hex_string'),         '',  'HEX string is RGB only');

#### new_from_any_input ################################################
my $fuchsia_array = Graphics::Toolkit::Color::Values->new_from_any_input([255, 0, 255]);
is( ref $fuchsia_array,               $module,  'object from regular RGB tuple');
is( $fuchsia_array->{'source_tuple'},      '',  'object source are RGB values');
is( $fuchsia_array->{'source_space_name'}, '',  'not from any other space');
is( $fuchsia_array->name,           'magenta',  'color has name "magenta"');
is_tuple( $RGB->round($fuchsia_array->{'rgb_tuple'}, 7), [1, 0, 1], [qw/red green blue/], 'fuchsia from array got right rgb tuple');

my $blue_hsl = Graphics::Toolkit::Color::Values->new_from_any_input({hue => 240, s => 100, l => 50});
is( ref $blue_hsl,                    $module,  'value object from HSL HASH');
is_tuple( $RGB->round($blue_hsl->{'source_tuple'}, 7), [0.6666667, 1, 0.5], [qw/cyan magenta yellow/], 'blue from HSL got right source tuple');
is( $blue_hsl->{'source_space_name'},   'HSL',  'cource space is correct');
is( $blue_hsl->name,                   'blue',  'color has name "blue"');
is_tuple( $RGB->round($blue_hsl->{'rgb_tuple'}, 7), [0, 0, 1], [qw/red green blue/], 'blue from hsl got right rgb tuple');

my $blue_hwb = Graphics::Toolkit::Color::Values->new_from_any_input('hwb( 240, 0%, 0% )');
is( ref   $blue_hwb,                  $module,'value object from HWB named string');
is_tuple( $RGB->round($blue_hwb->{'source_tuple'}, 7), [0.6666667, 0, 0], [qw/cyan magenta yellow/], 'blue from HWB got right source tuple');
is( $blue_hwb->{'source_space_name'},   'HWB',  'cource space is correct');
is( $blue_hwb->name,                   'blue',  'color has name "blue"');
is_tuple( $RGB->round($blue_hwb->{'rgb_tuple'}, 7), [0, 0, 1], [qw/red green blue/], 'blue from hwb got right rgb tuple');

#### name ################ #############################################
my $black = Graphics::Toolkit::Color::Values->new_from_any_input('ciexyz( 0, 0, 0)');
is( $black->name,                   'black',  'created black from CSS string in XYZ');
my $white = Graphics::Toolkit::Color::Values->new_from_any_input(['hsv', 0, 0, 100 ]);
is( $white->name,                   'white',  'created white from named ARRAY in HSV');

exit 0;
