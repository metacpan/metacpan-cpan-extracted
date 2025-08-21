#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 95;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';
use Graphics::Toolkit::Color::Space::Hub;

my $deformat      = \&Graphics::Toolkit::Color::Space::Hub::deformat;
my $dehash        = \&Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash;

#### deformat ##########################################################
my ($values, $space) = $deformat->([0, 255, 256]);
is( $space,                         'RGB', 'color triple can only be RGB');
is( ref $values,                  'ARRAY', 'got ARRAY tuple');
is( int @$values,                       3, 'RGB has 3 axis');
is( round_decimals( $values->[0], 5),   0, 'red value is right');
is( round_decimals( $values->[1], 5), 255, 'green value is right');
is( round_decimals( $values->[2], 5), 256, 'blue value got not  clamped yet');

($values, $space) = $deformat->('#FF2200');
is( $space,                         'RGB', 'RGB hex string');
is( ref $values,                  'ARRAY', 'got ARRAY tuple');
is( int @$values,                       3, 'RGB has 3 axis');
is( round_decimals( $values->[0], 5), 255, 'red value is right');
is( round_decimals( $values->[1], 5),  34, 'green value is right');
is( round_decimals( $values->[2], 5),   0, 'blue value has right value');

($values, $space) = $deformat->('#f20');
is( $space,                         'RGB', 'short RGB hex string');
is( ref $values,                  'ARRAY', 'got ARRAY tuple');
is( int @$values,                       3, 'RGB has 3 axis');
is( round_decimals( $values->[0], 5), 255, 'red value is right');
is( round_decimals( $values->[1], 5),  34, 'green value is right');
is( round_decimals( $values->[2], 5),   0, 'blue value has right value');

($values, $space) = $deformat->('blue');
is( $space,                     undef, 'deformat is not for color names');
($values, $space) = $deformat->('SVG:red');
is( $space,                     undef, 'deformat does not get confused by external color names');

($values, $space) = $deformat->('cmy:  1,0.1, 0 ');
is( $space,                     'CMY', 'named string works even with lower case');
is( ref $values,              'ARRAY', 'got ARRAY tuple even spacing was weird');
is( int @$values,                   3, 'CMY has 3 axis');
is( $values->[0], 1,     'cyan value is right');
is( $values->[1], 0.1,   'magenta value is right');
is( $values->[2], 0,     'yellow value has right value');

($values, $space) = $deformat->('ncol:  y10, 22%, 5.1% ');
is( ref $values,                '', 'wrong precision, NCol doesnt accept decimals');
($values, $space) = $deformat->('ncol:  y20, 22%, 5 ');
is( $space,                     'NCOL', 'color char can be lower case and percent is not mandatory');
is( ref $values,               'ARRAY', 'got ARRAY tuple even spacing was weird');
is( int @$values,                    3, 'NCol has 3 axis');
is( $values->[0],                  120, 'hue value is right');
is( $values->[1],                   22, 'w value is right');
is( $values->[2],                    5, 'b value is right');

($values, $space) = $deformat->('lab(0, -500, 200)');
is( $space,                     'LAB', 'got LAB css_string right');
is( ref $values,              'ARRAY', 'got ARRAY tuple');
is( int @$values,                   3, 'CIELAB has 3 axis');
is( $values->[0], 0,     'L* value is right');
is( $values->[1], -500,     'a* value is right');
is( $values->[2], 200,     'b* value has right value');

($values, $space) = $deformat->(['yuv', 0.4, -0.5, 0.5]);
is( $space,                     'YUV', 'found YUV named array');
is( ref $values,              'ARRAY', 'got ARRAY tuple');
is( int @$values,                   3, 'RGB has 3 axis');
is( $values->[0], 0.4, 'Y value is right');
is( $values->[1],-0.5,  'U value is right');
is( $values->[2], 0.5,  'V value got clamped to max');

($values, $space) = $deformat->({h => 360, s => 10, v => 100});
is( $space,          'HSV', 'found HSV short named hash');
is( ref $values,   'ARRAY', 'got ARRAY tuple');
is( int @$values,        3, 'HSV has 3 axis');
is( $values->[0],      360,  'hue value got rotated in');
is( $values->[1],       10,  'saturation value is right');
is( $values->[2],      100,  'value (kinda lightness) value got clamped to max');

($values, $space) = $deformat->({hue => 360, s => 10, v => 100});
is( $space,                     'HSV', 'found HSV short and long named hash');
is( ref $values,              'ARRAY', 'got ARRAY tuple');

($values, $space) = $deformat->({hue => 360, s => 10});
is( $space,                     undef, 'not found HSV hash due lacking value');

($values, $space) = $deformat->({h => 360, whiteness => 0, blackness => 20});
is( $space,                     'HWB', 'found HWB short and long named hash');
is( ref $values,              'ARRAY', 'got ARRAY tuple');
is( int @$values,                   3, 'HWB has 3 axis');
is( $values->[0], 360,      'hue value got rotated in');
is( $values->[1],  0,      'whiteness value is right');
is( $values->[2], 20,    'blackness value got clamped to max');

#### dehash ############################################################
my ($part_values, $space_name) = $dehash->( {hue => 20} );
is( $space_name,                   'HSL', 'HSL is first of the cylindrical spaces');
is( ref $part_values,             'ARRAY', 'partial value array is an ARRAY');
is( int @$part_values,                  1, 'value is on first position');
is( exists $part_values->[0],           1, 'and there is a value');
is( $part_values->[0],                 20, 'and it is the right value');
($part_values, $space_name) = $dehash->( {hUE => 20} );
is( $space_name,                     'HSL', 'dehash ignores casing');

($part_values, $space_name) = $dehash->( {hue => 19}, 'HSB' );
is( $space_name,                     'HSB', 'did found hue in HSB space when forced to');
is( ref $part_values,             'ARRAY', 'partial value array is an ARRAY');
is( int @$part_values,                  1, 'value is on first position');
is( exists $part_values->[0],           1, 'and there is a value');
is( $part_values->[0],                 19, 'and it is the right value');

($part_values, $space_name) = $dehash->(  );
is( $part_values,                     undef, 'need a hash as input');
($part_values, $space_name) = $dehash->( {hue => 20, h => 10} );
is( $part_values,                     undef, 'can not use axis name twice');
($part_values, $space_name) = $dehash->( {hue => 20, green => 10} );
is( $space_name,                     undef, 'can not mix axis names from spaces');
($part_values, $space_name) = $dehash->( {red => 20, green => 10, blue => 10, yellow => 20} );
is( $space_name,                     undef, 'can not use too my axis names');

($part_values, $space_name) = $dehash->( {X => 20, y => 10, Z => 30} );
is( $space_name,                     'XYZ', 'can mix upper and lower case axis names');
is( ref $part_values,              'ARRAY', 'partial value array is an ARRAY');
is( int @$part_values,                   3, 'partial value tuple has three keys');
is( defined $part_values->[0],           1, 'one key is on pos zero');
is( $part_values->[0],                  20, 'and it has right value');
is( defined $part_values->[1],           1, 'one key is on pos one');
is( $part_values->[1],                  10, 'and it has right value');
is( defined $part_values->[2],           1, 'one key is on pos two');
is( $part_values->[2],                  30, 'and it has right value');

($part_values, $space_name) = $dehash->( {C => 1, M => 0.3, Y => 0.4, K => 0} );
is( $space_name,                    'CMYK', 'works also with 4 element hashes');
is( ref $part_values,              'ARRAY', 'partial value array is an ARRAY');
is( int @$part_values,                   4, 'partial value tuple has four keys');
is( defined $part_values->[0],           1, 'one key is zero');
is( $part_values->[0],                   1, 'and it has right value');
is( defined $part_values->[1],           1, 'one key is on pos one');
is( $part_values->[1],                 0.3, 'and it has right value');
is( defined $part_values->[2],           1, 'one key is on pos two');
is( $part_values->[2],                 0.4, 'and it has right value');
is( defined $part_values->[3],           1, 'one key is on pos three');
is( $part_values->[3],                   0, 'and it has right value');

exit 0;
