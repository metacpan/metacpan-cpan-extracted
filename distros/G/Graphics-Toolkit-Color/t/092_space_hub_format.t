#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 60;
use Graphics::Toolkit::Color::Space::Hub;

my $deformat   = \&Graphics::Toolkit::Color::Space::Hub::deformat;
my $dehash     = \&Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash;
my $RGB        =   Graphics::Toolkit::Color::Space::Hub::default_space();
my $rgb_axis   = [qw/red green blue/];

#### deformat ##########################################################
my ($values, $space) = $deformat->([0, 255, 256]);
is_tuple( $RGB->round($values, 5), [0, 255, 256], $rgb_axis, 'deformat RGB ARRAY (tuple)');

($values, $space) = $deformat->('#FF2200');
is( $space, 'RGB', 'recignized short hex_string  as RGB');
is_tuple( $RGB->round($values, 5), [255, 34, 0], $rgb_axis, 'deformat long RGB hex_string');
($values, $space) = $deformat->('#f20');
is( $space, 'RGB', 'recignized long hex_string  as RGB');
is_tuple( $RGB->round($values, 5), [255, 34, 0], $rgb_axis, 'deformat short RGB hex_string');

($values, $space) = $deformat->('blue');
is( $space,                     undef, 'deformat is not for color names');
($values, $space) = $deformat->('SVG:red');
is( $space,                     undef, 'deformat does not get confused by external color names');

($values, $space) = $deformat->('cmy:  1,0.1, 0 ');
is( $space,                     'CMY', 'named string works even with lower case');
is_tuple( $values, [1, 0.1, 0], [qw/cyan magenta yellow/], 'deformat CMY named_string');

($values, $space) = $deformat->('ncol:  y10, 22%, 5.1% ');
is( ref $values,                '', 'wrong precision, NCol doesnt accept decimals');
($values, $space) = $deformat->('ncol:  y20, 22%, 5 ');
is( $space,                     'NCOL', 'identified NCol from named_string');
is_tuple( $RGB->round($values, 5), [120, 22, 5], [qw/hue whiteness blackness/], 'deformat NCol named_string');

($values, $space) = $deformat->('lab(0, -500, 200)');
is( $space,       'LAB', 'got LAB css_string right');
is_tuple( $values, [0, -500, 200], [qw/L* a* b*/], 'deformat LAB CSS_string');

($values, $space) = $deformat->(['yuv', 0.4, -0.5, 0.5]);
is( $space,        'YUV', 'found YUV named array');
is_tuple( $values, [0.4, -0.5, 0.5], [qw/Y U V/], 'deformat YUV named_array');

($values, $space) = $deformat->(['hunterLAB', 12, 2.5, 0.04]);
is( $space,                    'HUNTERLAB', 'found HUNTERLAB named array');
is_tuple( $values, [12, 2.5, 0.04], [qw/L* a* b*/], 'deformat HunterLAB named_array');

($values, $space) = $deformat->({h => 360, s => 10, v => 100});
is( $space,          'HSV', 'found HSV short named hash');
is_tuple( $values, [360, 10, 100], [qw/hue saturation value/], 'deformat HSV hash with short axis names');

($values, $space) = $deformat->({hue => 360, s => 10, v => 100});
is( $space,                     'HSV', 'found HSV short and long named hash');
is( ref $values,              'ARRAY', 'got ARRAY tuple');

($values, $space) = $deformat->({hue => 360, s => 10});
is( $space,                     undef, 'not found HSV hash due lacking value');

($values, $space) = $deformat->({h => 360, whiteness => 0, blackness => 20});
is( $space,                     'HWB', 'found HWB short and long named hash');
is_tuple( $values, [360, 0, 20], [qw/hue whiteness blacknes/], 'deformat HWB hash with mixed axis names');

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
