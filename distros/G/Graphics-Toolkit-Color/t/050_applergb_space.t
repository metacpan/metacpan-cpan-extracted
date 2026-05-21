#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 45;

my $module = 'Graphics::Toolkit::Color::Space::Instance::AppleRGB';
my $rgb_axis   = [qw/red green blue/];
my $xyz_axis   = [qw/X Y Z/];

my $space = eval "require $module";
is( not($@), 1, 'could load the module'); # say $@;
is( ref $space, 'Graphics::Toolkit::Color::Space', 'got space object by loading module');
is( $space->name,                      'APPLERGB', 'color space has right name');
is( $space->name('alias'),                     '', 'APPLERGB has no alias');
is( $space->is_name('apple-RGB'),               1, 'one way to write APPLERGB');
is( $space->is_name('RGB'),                     0, 'AppleRGB is not SRGB');
is( $space->axis_count,                         3, 'lin RGB color space has 3 axis');
is( $space->is_euclidean,                       1, 'lin RGB is euclidean');
is( $space->is_cylindrical,                     0, 'lin RGB is not cylindrical');

is( $space->is_value_tuple([0,0,0]),                   1,  'vector has 3 elements');
is( $space->can_convert('XYZ'),                        1,  'do only convert from and to XYZ');
is( $space->can_convert('x.y.z.'),                     1,  'color space name can be written creatively');
is( $space->can_convert('RGB'),                        0,  'does not convert directly to RGB');
is( $space->is_partial_hash({r => 1, b => 0, g=>0}),   1,  'found hash with some short axis names as keys');
is( $space->is_partial_hash({green => 1, blue => 0}),  1,  'found hash with some other long axis names as keys');
is( $space->is_partial_hash({green => 1, cyan => 0}),  0,  'some axis name match some do not');

is( ref $space->check_value_shape( [0,0,0]),    'ARRAY', 'check AppleRGB values works on lower bound values');
is( ref $space->check_value_shape( [1, 1, 1]),  'ARRAY', 'check AppleRGB values works on upper bound values');
is( ref $space->check_value_shape( [0,0]),           '', "AppleRGB got too few values");
is( ref $space->check_value_shape( [0, 0, 0, 0]),    '', "AppleRGB got too many values");
is( ref $space->check_value_shape( [-0.1, 0, 0]),    '', "red value is too small");
is( ref $space->check_value_shape( [1.1, 0, 0]),     '', "reg value is too big");
is( ref $space->check_value_shape( [0, -0.001, 0]),  '', "green value is too small");
is( ref $space->check_value_shape( [0, 1.1, 0]),     '', "green value is too big");
is( ref $space->check_value_shape( [0, 0, -0.1 ] ),  '', "blue value is too small");
is( ref $space->check_value_shape( [0, 0, 1.1] ),    '', "blue value is too big");

my ($rgb, $name) = $space->deformat('apple_rgb: 0.1, 0.2, 0.8');
is( $name,   'named_string', 'recognized named string format');
is_tuple( $rgb, [0.1, 0.2, 0.8], $rgb_axis, 'got values from named_string');

($rgb, $name) = $space->deformat([ 33, 44, 55]);
is( $rgb,   undef,     'array format is RGB only');

($rgb, $name) = $space->deformat([AppleRGB => [0, 0.2, 1.2]]);
is( $name,   'named_array', 'recognized named named array format with nested array');
is_tuple( $rgb, [0, 0.2, 1.2], $rgb_axis, 'got values from named_array with nested tuple');

is( $space->format([0.2,.3,.7],'named_string'),  'applergb: 0.2, 0.3, 0.7',  'formatted back into named string');

$rgb = $space->clamp([]);
is_tuple( $rgb, [0, 0, 0], $rgb_axis, 'created default color black by clamping empty array ref');

$rgb = $space->clamp([0, 1]);
is_tuple( $rgb, [0, 1, 0], $rgb_axis, 'clamp inserted zero as missing value');

$rgb = $space->clamp([-0.1, 2, 0.5, 0.4, 0.5]);
is_tuple( $rgb, [0, 1, 0.5], $rgb_axis, 'clamp removed superfluous values and moved too small(red) to min. and too large(green) to max');

my $d = $space->delta([.2,.2,.2],[.2,.2,.2]);
is_tuple( $d, [0, 0, 0], $rgb_axis, 'vector has with itself zero delta');

$d = $space->delta([0.1,0.2,0.4],[0, 0.5, 1]);
is_tuple( $d, [-0.1, 0.3, 0.6], $rgb_axis, 'computed delta vector between bery different vectors');

$rgb = $space->convert_from( 'XYZ', [0, 0, 0], 1);
is_tuple( $rgb, [0, 0, 0], $rgb_axis, 'convert black from XYZ');

my $xyz = $space->convert_to( 'XYZ', [0, 0, 0 ]);
is_tuple( $xyz, [0, 0, 0], $xyz_axis, 'convert black back to XYZ');

$rgb = $space->convert_from( 'XYZ', [1, 1, 1]);
is_tuple( $space->round( $rgb, 7), [1, 1, 1], $rgb_axis, 'convert white from XYZ');

$xyz = $space->convert_to( 'XYZ', [1, 1, 1 ]);
is_tuple( $space->round( $xyz, 7 ), [1, 1, 1], $xyz_axis, 'converted white from Apple RGB into XYZ');

$rgb = $space->convert_from( 'XYZ', [1, 0.5, 0]);
is_tuple( $space->round( $rgb, 9), [1.534190627,  -0.157584467, -0.196553855], $rgb_axis, 'convert orange from XYZ');#66

$xyz = $space->convert_to( 'XYZ', [1.534190627,  -0.157584467, -0.196553855]);
is_tuple( $space->round( $xyz, [6,7,7]), [1, 0.5, 0], $xyz_axis, 'convert orange back to XYZ');

$rgb = $space->convert_from( 'XYZ', [.1, .2, .9]);
is_tuple( $space->round( $rgb, 9), [-0.635101473, 0.541496664, 1.013065291], $rgb_axis, 'convert deep blue from XYZ');

$xyz = $space->convert_to( 'XYZ', [-0.635101473, 0.541496664, 1.013065291]);
is_tuple( $space->round( $xyz, [6,7,7] ), [.1, .2, .9], $xyz_axis, 'converted deep blue back from AppleRGB back into XYZ');

exit 0;
