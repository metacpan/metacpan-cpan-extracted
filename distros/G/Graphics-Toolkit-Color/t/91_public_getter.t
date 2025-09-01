#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 92;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';
use Graphics::Toolkit::Color qw/color/;

my $red   = color(255,0,0);
my $blue  = color({r => 0, g => 0, b=>255});
my $purple = color({hue => 300, s => 100, l => 25});
my $black = color([0,0,0]);
my $white = color('cmy',0,0,0);
my @names;

is( $red->name,          'red', 'color name "red" is correct');
is( $blue->name,        'blue', 'color name "blue" is correct');
is( $purple->name,    'purple', 'color name "purple" is correct');
is( $black->name,      'black', 'color name "black" is correct');
is( $white->name,      'white', 'color name "white" is correct');

is( $red->closest_name,          'red', 'color "red" is also closest name');
is( $blue->closest_name,        'blue', 'color "blue" is also closest name');
is( $purple->closest_name,    'purple', 'color "purple" is also closest name');
is( $black->closest_name,      'black', 'color "black" is also closest name');
is( $white->closest_name,      'white', 'color "white" is also closest name');

@names = $blue->name(all => 1, full => 1);
is( int @names,                 2, '"blue" has two names');
is( $names[0],             'blue', '"blue" is first, no default name space name in color name');
is( $names[1],            'blue1', '"blue1" is second"');
@names = sort $blue->name(all => 1, distance => 25);
is( int @names,                 3, 'around "blue" with distance 25 you get 3 colors');
is( $names[0],             'blue', '"blue" is first, no default name space name in color name');
is( $names[1],            'blue1', '"blue1" is second"');
is( $names[2],            'blue2', '"blue2" is third"');

my ($name, $d) = $red->closest_name;
is( $name,               'red', 'color name is "red" also in array context');
is( $d,                      0, 'and has no distance');
($name, $d) = $blue->closest_name;
is( $name,              'blue', 'color name is "blue" also in array context');
is( $d,                      0, 'and has no distance');
($name, $d) = $purple->closest_name;
is( $name,            'purple', 'color name is "purple" also in array context');
is( $d,                      0, 'and has no distance');
($name, $d) = $black->closest_name;
is( $name,             'black', 'color name is "black" also in array context');
is( $d,                      0, 'and has no distance');
($name, $d) = $white->closest_name;
is( $name,             'white', 'color name is "white" also in array context');
is( $d,                      0, 'and has no distance');

my $snow = color(['rgb', 254, 255, 255]);
is( $snow->name,               '', 'this color has no name in default constants');
($name, $d) = $snow->closest_name;
is( $name,             'white', 'color "white" is closest to snow');
is( $d,                      1, 'and has a distance of 1');
is( round_decimals($snow->distance($white), 5), 1, 'distance method calculates (almost) the same');
is( round_decimals($snow->distance(to => $white), 5), 1, 'use named argument to calculate distance');
is( round_decimals($snow->distance(to => $white, range => 510), 3), 2, 'test reaction to the "range" argument');
is( round_decimals($snow->distance(to => $white, select => 'red'), 5), 1, 'test reaction to the "select" argument');
is( round_decimals($snow->distance(to => $white, select => 'blue'), 5), 0, 'select axis with no value difference');
is( round_decimals($snow->distance(to => $white, select => ['red','blue']), 5), 1, 'select axis with and without value difference');
is( round_decimals($snow->distance(to => $white, in => 'cmy', range => 255), 5), 1, 'test reaction to the "in" argument');
is( ref $snow->distance( to => $white, blub => '-'),           '', 'false arguments get caught');
is( ref $snow->distance( in => 'LAB'),                         '', 'missing required argument gets caught');

my @values = $blue->values();
is( int @values,                3, 'default result for "values" are 3 numbers');
is( $values[0],                 0, 'red value is correct');
is( $values[1],                 0, 'green value is correct');
is( $values[2],               255, 'blue red value is correct');

@values = $blue->values(as => 'array');
is( int @values,                 1, 'ordered one ARRAY ref');
is( ref $values[0],        'ARRAY', 'it is an ARRAY ref');
is( int @{$values[0]},           3, 'has three values inside');
is( $values[0][0],               0, 'red value is correct');
is( $values[0][1],               0, 'green value is correct');
is( $values[0][2],             255, 'blue value is correct');

@values = $blue->values(as => 'named_array');
is( int @values,                 1, 'named ARRAY ref');
is( ref $values[0],        'ARRAY', 'is an ARRAY ref');
is( int @{$values[0]},           4, 'has four values inside');
is( $values[0][0],           'RGB', 'color space name is first');
is( $values[0][1],               0, 'red value is correct');
is( $values[0][2],               0, 'green value is correct');
is( $values[0][3],             255, 'blue value is correct');
is( ref $blue->values( in => 'LAB', as => 'array'),       '', 'ARRAY ref format  is RGB only');
is( ref $blue->values( in => 'LAB', as => 'hex_string'),  '', 'hex_string format is RGB only');
is( ref $blue->values( in => 'LAB', was => 'array'),      '', 'reject fantasy arguments');
is( ref $blue->values( in => 'LAB', suffix => {}),        '', 'bad ref type for suffix def');
is( ref $blue->values( in => 'LAB', suffix => [1,2]),     '', 'suffix def too short');
is( ref $blue->values( in => 'LAB', suffix => [1,2,3,4]), '', 'suffix def too long');

@values = $blue->values(in => 'CMYK');
is( int @values,                4, 'CMYK has 4 values');
is( $values[0],                 1, 'cyan value is correct');
is( $values[1],                 1, 'magenta value is correct');
is( $values[2],                 0, 'yellow red value is correct');
is( $values[3],                 0, '"key" value is correct');

is( $blue->values(as => 'css_string'),      'rgb(0, 0, 255)', 'blue in CSS string format');
is( $blue->values(as => 'named_string'),    'rgb: 0, 0, 255', 'blue in named string format');
is( $blue->values(as => 'hex_string'),             '#0000FF', 'blue in hex string format');
is( $snow->values(as => 'css_string'),      'rgb(254, 255, 255)', 'blue in CSS string format');
is( $snow->values(as => 'named_string'),    'rgb: 254, 255, 255', 'blue in named string format');
is( $snow->values(as => 'hex_string'),                 '#FEFFFF', 'blue in hex string format');
is( $snow->values(as => 'HEX_string'),                 '#FEFFFF', 'format name is case insensitive');
is( $red->values(in => 'HWB', as => 'named_string'), 'hwb: 0, 0%, 0%', 'red as named string in HWB');
is( $red->values(in => 'HWB', as => 'named_string', suffix => ''),        'hwb: 0, 0, 0',           'without any suffix');
is( $red->values(in => 'RGB', as => 'css_string', suffix => ['-','/','']),'rgb(255-, 0/, 0)',       'RGB with taylor made suffix');
is( $red->values(in => 'XYZ', as => 'css_string' ),                   'xyz(41.246, 21.267, 1.933)', 'XYZ red CSS string ');
is( $red->values(in => 'XYZ', as => 'css_string', precision => 1 ),   'xyz(41.2, 21.3, 1.9)',       'XYZ red CSS string with reduced precision');
is( $red->values(in => 'XYZ', as => 'css_string', precision => [3,2,0] ),'xyz(41.246, 21.27, 2)',   'XYZ red CSS string with inidividual precision');
is( $blue->values(in => 'RGB', as => 'named_string', range => '10'),     'rgb: 0, 0, 10',           'RGB blue with custom ranges');
is( $blue->values(in => 'RGB', as => 'named_string', range => [[-1,1],[-2,2],1]), 'rgb: -1, -2, 1', 'RGB blue with with very custom ranges');

my $values = $blue->values( as => 'hash');
is( ref $values,           'HASH', 'got a value HASH ref');
is( keys %$values,              3, 'RGB has 3 keays');
is( $values->{'red'},           0, '"red" value is correct');
is( $values->{'green'},         0, '"green" value is correct');
is( $values->{'blue'},        255, '"blue" value is correct');

$values = $blue->values( in => 'HSL', as => 'char_hash', suffix => '');
is( ref $values,           'HASH', 'got a value HASH ref');
is( keys %$values,              3, 'HSL has 3 keays');
is( $values->{'h'},           240, '"hue" value is correct');
is( $values->{'s'},           100, '"saturation" value is correct');
is( $values->{'l'},            50, '"lightness" value is correct');

exit 0;
