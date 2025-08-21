#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 62;
use Benchmark;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Name::Scheme';
use_ok( $module, 'could load the module');

my ($scheme, $names, @names, $values, $distance);
$scheme = Graphics::Toolkit::Color::Name::Scheme->new('');
is( ref $scheme,                $module, 'could create empty object');
@names = $scheme->all_names();
is( int @names,                       0, 'empty object has no names stored');
is( $scheme->is_name_taken('white'),  0, 'color "white" is not part of scheme');
is( $scheme->is_name_taken('black'),  0, 'color "black" is not part of scheme');
is( $scheme->values_from_name('black'),  '', 'can not get values of "black"');
is( $scheme->values_from_name('white'),  '', 'can not get values of "white"');
is( $scheme->names_from_values([255,255,255]),  '', 'can not get name "white" by values');
is( $scheme->closest_names_from_values([255,255,255]),  '', 'can not get color name that is near "white" by values');
is( $scheme->names_from_values([  0,  0,  0]),  '', 'can not get name "black" by values');
is( $scheme->add_color('white',[255,255,255]),  1, 'added color "white"');
is( $scheme->add_color('black',[  0,  0,  0]),  1, 'added color "black"');

is( $scheme->is_name_taken('white'),           1, '"white" is noe part of scheme');
is( $scheme->is_name_taken('black'),           1, '"black" is noe part of scheme');
$names = $scheme->names_from_values([255,255,255]);
is( ref $names,                          'ARRAY',  'get name "white" by values');
is( @$names,                                   1,  'no other color has same values');
is( $names->[0],                         'white',  'the name is correct');
$names = $scheme->names_from_values([0,0,0]);
is( ref $names,                          'ARRAY',  'get names for "black" values');
is( @$names,                                   1,  'one color');
is( $names->[0],                         'black',  'the name is correct');
$values = $scheme->values_from_name('white');
is( ref $values,                        'ARRAY',  'got values from name "white"');
is( @$values,                                 3,  'RGB are 3 values');
is( $values->[0],                           255,  'red value is right');
is( $values->[0],                           255,  'green value is right');
is( $values->[0],                           255,  'blue value is right');

$values = $scheme->values_from_name('black');
is( ref $values,                        'ARRAY',  'got values from name "black"');
is( @$values,                                 3,  'RGB are 3 values');
is( $values->[0],                             0,  'red value is right');
is( $values->[0],                             0,  'green value is right');
is( $values->[0],                             0,  'blue value is right');

($names, $distance) = $scheme->closest_names_from_values( [1,0,0] );
is( ref $names,                          'ARRAY',  'found colors near black');
is( @$names,                                   1,  'one color');
is( $names->[0],                         'black',  'the name is correct');
is( $distance,                                 1,  'computed the right distance to black');
($names, $distance) = $scheme->closest_names_from_values( [255,252,251] );
is( ref $names,                          'ARRAY',  'found colors near white');
is( @$names,                                   1,  'one color');
is( $names->[0],                         'white',  'the name is correct');
is( $distance,                                 5,  'computed the right distance to white');

is( $scheme->is_name_taken('snow'),            0, 'color "snow" is not part of scheme');
is( $scheme->add_color('snow',[255,255,255]),  1, 'added "white"');
is( $scheme->is_name_taken('snow'),            1, 'color "snow" is now part of scheme');
$values = $scheme->values_from_name('snow');
is( ref $values,                        'ARRAY',  'got values from color name "snow"');
is( @$values,                                 3,  'RGB are 3 values');
is( $values->[0],                           255,  'red value is right');
is( $values->[0],                           255,  'green value is right');
is( $values->[0],                           255,  'blue value is right');
$names = $scheme->names_from_values([255,255,255]);
is( ref $names,                          'ARRAY',  'get color names from 255, 255, 255');
is( @$names,                                   2,  'its two colors now');
is( $names->[0],                         'white',  'first is "white"');
is( $names->[1],                          'snow',  'the second is "snow"');
($names, $distance) = $scheme->closest_names_from_values( [254, 253, 253] );
is( ref $names,                          'ARRAY',  'found colors near "white"');
is( @$names,                                   2,  'two colors');
is( $names->[0],                         'white',  'first is "white"');
is( $names->[1],                          'snow',  'the second is "snow"');
is( $distance,                                 3,  'computed the right distance to black');

is( $scheme->add_color('steel',[253,253,253]),  1, 'added color "steel"');
($names, $distance) = $scheme->closest_names_from_values( [254, 254, 254] );
$names = [sort @$names];
is( ref $names,                          'ARRAY',  'found colors near "white" ish');
is( @$names,                                   3,  'two colors');
is( $names->[0],                          'snow',  'first color name sorted is is "snow"');
is( $names->[1],                         'steel',  'the second is "steel"');
is( $names->[2],                         'white',  'third is "white"');
is( $distance,                            sqrt 3,  'computed the right distance to black');

exit 0;
