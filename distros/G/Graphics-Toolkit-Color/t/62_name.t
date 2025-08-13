#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 59;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util ':all';

my $module = 'Graphics::Toolkit::Color::Name';
my $space_ref = 'Graphics::Toolkit::Color::Space';

use_ok( $module, 'could load the module');
my @names = Graphics::Toolkit::Color::Name::all();

my $is_taken           = \&Graphics::Toolkit::Color::Name::is_taken;
my $name_from_rgb      = \&Graphics::Toolkit::Color::Name::name_from_rgb;
my $name_from_hsl      = \&Graphics::Toolkit::Color::Name::name_from_hsl;
my $add_rgb            = \&Graphics::Toolkit::Color::Name::add_rgb;
my $add_hsl            = \&Graphics::Toolkit::Color::Name::add_hsl;
my $names_in_hsl_range = \&Graphics::Toolkit::Color::Name::names_in_hsl_range;

is( int @names,               716,       'all consants are there' );
is( $is_taken->('red'),         1,       '"red" is a known constant' );
is( $is_taken->('RED'),         1,       'color constants are case insensitive' );
is( $is_taken->("r_e'd"),       1,       'some special characters are also ignored' );
is( $is_taken->('blue'),        1,       '"blue" is a known constant' );
is( $is_taken->('coconut'),     0,       '"coconut" is not a known constant' );

my $values = Graphics::Toolkit::Color::Name::rgb_from_name('red');
is( ref $values,      'ARRAY',       'got tuple with RGB values of "red"' );
is( int @$values,           3,       'tuple contains three values' );
is( $values->[0],         255,       'red value is correct' );
is( $values->[1],           0,       'green value is correct' );
is( $values->[2],           0,       'blue value is correct' );
$values = Graphics::Toolkit::Color::Name::rgb_from_name('coconut');
is( ref $values,           '',       'got no tuple for unknown color constant' );

$values = Graphics::Toolkit::Color::Name::hsl_from_name('red');
is( ref $values,      'ARRAY',       'got tuple with HSL values of "red"' );
is( int @$values,           3,       'tuple contains three values' );
is( $values->[0],           0,       'hue value is correct' );
is( $values->[1],         100,       'saturation value is correct' );
is( $values->[2],          50,       'lightness value is correct' );
$values = Graphics::Toolkit::Color::Name::hsl_from_name('coconut');
is( ref $values,           '',       'got no tuple for unknown color constant' );

is( $name_from_rgb->([255,0,0]),             'red',       'found red constant by RGB values' );
my $color_name = $name_from_rgb->([0,0,255]);
is( $color_name,                            'blue',       'found blue constant by RGB values in scalar context' );
my @color_name = $name_from_rgb->([0,0,255]);
is( int @color_name,                             2,       'in ARRAY context you get two blue names in RGB' );
is( $color_name[0],                         'blue',       'first one is "blue"' );
is( $color_name[1],                        'blue1',       'second one is "blue1"' );
is( $name_from_rgb->([1,1,255]),                '',       'no color with values 1, 1, 255' );
is( length $add_rgb->('blue', [1, 0, 255]),     61,       'name blue is already in store' );
is( $add_rgb->('blue_top',  [0, 0, 255]),        0,       'added third name for blue on top' );
@color_name = $name_from_rgb->([0,0,255]);
is( int @color_name,                             3,       'in ARRAY context you get several blue names' );
is( $color_name[2],                      'bluetop',       'new blue name is last in list' );
is( $add_rgb->('bluuu',  [1, 1, 255]),           0,       'could add my custom blue' );
is( $name_from_rgb->([1,1,255]),           'bluuu',       'can retrieve newly stored constant' );
is( $name_from_hsl->([0,100,50]),            'red',       'found red constant by HSL values' );
is( $name_from_hsl->([240,100,50]),         'blue',       'found blue constant by HSL values' );
$color_name = $name_from_hsl->([240,100,50]);
is( $color_name,                            'blue',       'found blue constant by HSL values in scalar context' );
@color_name = $name_from_hsl->([240,100,50]);
is( int @color_name,                             4,       'in ARRAY context you get 4 blue names now in HSL' );
is( $color_name[0],                         'blue',       'first one is "blue"' );
is( $color_name[1],                        'blue1',       'second one is "blue1"' );
is( $color_name[2],                      'bluetop',       'third one is "bluetop"' );
is( $color_name[3],                        'bluuu',       'fourth one is "bluuu"' );
is( $name_from_hsl->([241,100,50]),             '',       'custom blue is not in store yet' );
is( ref $add_hsl->('blue', [240,100,50]),       '',       'name blue is already in store, also under HSL' );
is( $add_hsl->('blauu',  [241,100,50]),          0,       'could add my custom blue' );
is( $name_from_hsl->([241,100,50]),        'blauu',       'can retrieve newly stored blue as HSL constant' );

my ($names, $d) = $names_in_hsl_range->([240,100,50], 3);
@color_name = sort @$names[0..3];
is( ref $names,         'ARRAY',       'got near color names in an ARRAY' );
is( ref $d,             'ARRAY',       'got near color distances in an ARRAY' );
is( int @$names,              6,       'its six colors' );
is( int @$d,                  6,       'has to be also six distances' );
is( $names->[5],        'blue2',       'far away is "blue2"' );
is( $d->[5],                  3,       '"blue2" has the greatest distance' );
is( $names->[4],        'blauu',       'closer is "blauu"' );
is( $d->[4],                  1,       '"blauu" has very little distance' );
is( $color_name[0],      'blue',       '"blue" is the wanted color' );
is( $d->[0],                  0,       '"blue" has no distance' );
is( $color_name[1],     'blue1',       '"blue1" is the wanted color' );
is( $d->[1],                  0,       '"blue1" has no distance' );
is( $color_name[2],   'bluetop',       '"bluetop" is the wanted color' );
is( $d->[2],                  0,       '"bluetop" has no distance' );
is( $color_name[3],     'bluuu',       '"bluuu" is the wanted color' );
is( $d->[3],                  0,       '"bluuu" has no distance' );

exit 0;
