#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 66;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Name';
use_ok( $module, 'could load the module');

my $get_values          = \&Graphics::Toolkit::Color::Name::get_values;
my $from_values         = \&Graphics::Toolkit::Color::Name::from_values;
my $closest_from_values = \&Graphics::Toolkit::Color::Name::closest_from_values;
my $all                 = \&Graphics::Toolkit::Color::Name::all;
my $try_get_scheme      = \&Graphics::Toolkit::Color::Name::try_get_scheme;
my $add_scheme          = \&Graphics::Toolkit::Color::Name::add_scheme;
my $scheme_ref          = 'Graphics::Toolkit::Color::Name::Scheme';
my $default_scheme      = $try_get_scheme->('default');
my (@names, $names, $values);

is( ref $try_get_scheme->(),          $scheme_ref, 'get default scheme when leaving out argument');
is( ref $default_scheme,              $scheme_ref, 'get default scheme when requesting it');
is( $default_scheme,          $try_get_scheme->(), 'both are the same');
is( $default_scheme->is_name_taken('red'),      1, '"red" is a known constant' );
is( $default_scheme->is_name_taken('RED'),      1, 'color constants are case insensitive' );
is( $default_scheme->is_name_taken("r_e'd"),    1, 'some special characters are also ignored' );
is( $default_scheme->is_name_taken('blue'),     1, '"blue" is a known constant' );
is( $default_scheme->is_name_taken('coconut'),  0, '"coconut" is not a known constant' );

@names = Graphics::Toolkit::Color::Name::all();
is( int @names,               716,       'all default consants are there' );
#$values = Graphics::Toolkit::Color::Name::get_values('SVG:red');
$values = $get_values->('red');
is( ref $values,         'ARRAY',       'got value tuple of color red' );
is( int @$values,              3,       'it has three values' );
is( $values->[0],            255,       'red value is correct' );
is( $values->[1],              0,       'green value is correct' );
is( $values->[2],              0,       'blue value is correct' );

@names = Graphics::Toolkit::Color::Name::from_values([255,0,0]);
is( int @names,                1,       'no second arg, get only one name "from_values"');
is( $names[0],             'red',       'and its name is "red"');
@names = Graphics::Toolkit::Color::Name::from_values([255,0,0], undef, 'all' );
is( int @names,                2,       'all names were requested "from_values"' );
is( $names[0],             'red',       'it is also "red" on first position' );
is( $names[1],            'red1',       'it is "red1" on second position' );
@names = Graphics::Toolkit::Color::Name::from_values([255,0,0], undef, 'all', 'full' );
is( int @names,                2,       'names do not expand when in default scheme' );
is( $names[0],             'red',       'it is also "red" on first position' );
is( $names[1],            'red1',       'it is "red1" on second position' );

@names = Graphics::Toolkit::Color::Name::closest_from_values([255,0,0] );
is( int @names,                2,       'got names and distance from "closest_from_values"');
is( $names[0],             'red',       'and its name is "red"' );
is( $names[1],                 0,       'has no distance' );
@names = Graphics::Toolkit::Color::Name::closest_from_values([255,0,0], undef, 'all' );
is( int @names,                2,       'got all names and distance from "closest_from_values"');
is( ref $names[0],       'ARRAY',       'names ARRAY on first position');
is( @{$names[0]},              2,       'it has two names');
is( $names[0][0],          'red',       'first is "red"');
is( $names[0][1],         'red1',       'second is is "red1"');
is( $names[1],                 0,       'has no distance');
@names = Graphics::Toolkit::Color::Name::closest_from_values([255,1,0] );
is( int @names,                2,       'this time there is a distance to red');
is( $names[0],             'red',       'and its name is "red"' );
is( $names[1],                 1,       'has distance of one' );
@names = Graphics::Toolkit::Color::Name::closest_from_values([253, 2, 1], undef, 'all' );
is( int @names,                2,       'got all names and distance from color more far away');
is( ref $names[0],       'ARRAY',       'got names ARRAY for color away');
is( @{$names[0]},              2,       'it has two names');
is( $names[0][0],          'red',       'first is "red"');
is( $names[0][1],         'red1',       'second is is "red1"');
is( $names[1],                 3,       'has distance of 2');


my $scheme = Graphics::Toolkit::Color::Name::Scheme->new();
$scheme->add_color('steel',[253,253,253]);
is( $default_scheme->is_name_taken('steel'),      0, '"steel" is an unknown color to default scheme' );
is( ref $try_get_scheme->('new'),                '', '"new" scheme is unknown');
is( ref $add_scheme->($scheme, 'new'),  $scheme_ref, 'could add the color scheme "new"');
is( ref $try_get_scheme->('new'),       $scheme_ref, '"new" scheme is now known');

$values = $get_values->('steel');
is( ref $values,              '',       'can not get "steel" color values if not call scheme' );
$values = $get_values->('steel', 'new');
is( ref $values,         'ARRAY',       'asking for "new" scheme, now I get it' );
is( int @$values,              3,       'tuple has three values' );
is( $values->[0],            253,       'red value is correct' );
is( $values->[1],            253,       'green value is correct' );
is( $values->[2],            253,       'blue value is correct' );

@names = Graphics::Toolkit::Color::Name::from_values([253,253,253], 'new');
is( int @names,                1,       'get a name from "new" scheme');
is( $names[0],           'steel',       'and its "steel"');
@names = Graphics::Toolkit::Color::Name::from_values([253,253,253]);
is( int @names,                1,       'can not get steel from dfault scheme');
is( $names[0],                '',       'name is empty');
@names = Graphics::Toolkit::Color::Name::from_values([253,253,253], ['new','default']);
is( int @names,                1,       'multi scheme search is success');
is( $names[0],           'steel',       'right color name');

@names = Graphics::Toolkit::Color::Name::closest_from_values([254, 254, 254], ['new','default'] );
is( int @names,                2,       'multi search with first wins strategy');
is( $names[0],           'steel',       'got name from first scheme');
is( $names[1],  round_decimals(sqrt 3, 5),       'distance is sqrt 3' );
@names = Graphics::Toolkit::Color::Name::closest_from_values([254, 254, 254], ['new','default'], 'all' );
is( int @names,                2,       'get multi scheme findings with same distance');
is( ref $names[0],       'ARRAY',       'got names ARRAY');
is( @{$names[0]},              2,       'it has three names');
is( $names[0][0],        'steel',       '"steel" is first due scheme "new" was named first');
is( $names[0][1],        'white',       'second is "white"');
is( $names[1],  round_decimals(sqrt 3, 5),       'distance is sqrt 3' );

1;
