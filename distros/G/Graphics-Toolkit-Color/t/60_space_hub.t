#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 227;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';

my $module = 'Graphics::Toolkit::Color::Space::Hub';
my $space_ref = 'Graphics::Toolkit::Color::Space';
use_ok( $module, 'could load the module');

my $convert       = \&Graphics::Toolkit::Color::Space::Hub::convert;
my $deconvert     = \&Graphics::Toolkit::Color::Space::Hub::deconvert;
my $deformat      = \&Graphics::Toolkit::Color::Space::Hub::deformat;
my $dehash        = \&Graphics::Toolkit::Color::Space::Hub::deformat_partial_hash;
my $distance      = \&Graphics::Toolkit::Color::Space::Hub::distance;

is( ref Graphics::Toolkit::Color::Space::Hub::get_space('RGB'),  $space_ref, 'RGB is a color space');
is( Graphics::Toolkit::Color::Space::Hub::is_space_name($_),   1, "found $_ color space")
    for qw /RGB CMY CMYK HSL HSv HSB HWB NCol YIQ YUV CIEXYZ CIELAB CIELUV CIELCHab CIELCHuv/;
my @names = Graphics::Toolkit::Color::Space::Hub::all_space_names();
is( int @names,  20, 'intalled 20 space names');
is( Graphics::Toolkit::Color::Space::Hub::is_space_name($_),      1, "$_ is a space name") for @names;

my $Tspace = Graphics::Toolkit::Color::Space->new( axis => [qw/one two three/], range => 10 );
   $Tspace->add_converter(          'RGB', \&p, \&p );
   sub p { @{$_[0]} }

my $ret = Graphics::Toolkit::Color::Space::Hub::add_space( $Tspace );
is( $ret, 1, "could add test color space");
is( Graphics::Toolkit::Color::Space::Hub::is_space_name('OTT'),          1, 'test space was installed');
is( Graphics::Toolkit::Color::Space::Hub::get_space('OTT'),   $Tspace, 'got access to test space');
@names = Graphics::Toolkit::Color::Space::Hub::all_space_names();
is( int @names,  21, 'intalled 21st space name');
is( ref Graphics::Toolkit::Color::Space::Hub::remove_space('TTT'), '', 'try to delete unknown space');
is( ref Graphics::Toolkit::Color::Space::Hub::remove_space('OTT'), $space_ref, 'removed test space');
is( Graphics::Toolkit::Color::Space::Hub::is_space_name('OTT'),          0, 'test space is gone');
is( Graphics::Toolkit::Color::Space::Hub::get_space('OTT'),        '', 'no access to test space');
is( ref Graphics::Toolkit::Color::Space::Hub::remove_space('OTT'), '', 'test space was already removed');
is( Graphics::Toolkit::Color::Space::Hub::is_space_name('OTT'),          0, 'test space is still gone');
@names = Graphics::Toolkit::Color::Space::Hub::all_space_names();
is( int @names,  20, 'intalled again only 20 space names');

my $rgb_name = Graphics::Toolkit::Color::Space::Hub::default_space_name();
is( Graphics::Toolkit::Color::Space::Hub::is_space_name($rgb_name),             1, 'default space name is valid');
is( ref Graphics::Toolkit::Color::Space::Hub::get_space($rgb_name),    $space_ref, 'can get default space');
is( ref Graphics::Toolkit::Color::Space::Hub::default_space(),    $space_ref, 'default space is a space');
my %sn = map {$_ => 1} @names;
is( $sn{$rgb_name},  1  , 'default space is among color spaces');

########################################################################
is( ref $convert->(),                       '', 'convert needs at least one argument');
is( ref $convert->({r => 1,g => 1,b => 1}), '', 'convert only value ARRAY no HASH');
is( ref $convert->([0,0]),                  '', 'tuple has not enough values');
is( ref $convert->([0,0,0], 'Jou'),         '', 'convert needs a valid target name space');

is( ref $deconvert->(),                       '', 'deconvert needs at least one argument');
is( ref $deconvert->('JAP'),                  '', 'deconvert needs a valid source space name name');
is( ref $deconvert->('RGB', {r => 1,g => 1,b => 1}), '', 'deconvert tule as ARRAY');
is( ref $deconvert->('JAP', [0,0,0]),                '', 'space name bad but tuple good');


my $tuple = $convert->([0,1/255,1], 'RGB');
is( ref $tuple,      'ARRAY', 'did minimal none conversion');
is( int @$tuple,           3, 'RGB has 3 axis');
is( $tuple->[0],           0, 'red value is right');
is( $tuple->[1],           1, 'green value is right');
is( $tuple->[2],         255, 'blue value is right');

$tuple = $convert->([0,1/255,1], 'RGB', 'normal');
is( int @$tuple,           3, 'wanted  normalized result');
is( $tuple->[0],           0, 'red value is right');
is( $tuple->[1],       1/255, 'green value is right');
is( $tuple->[2],           1, 'blue value is right');

$tuple = $convert->([.1, .2, .3], 'YUV', 1, 'YUV', [1, .1, 0]);
is( int @$tuple,           3, 'take source values instead of convert RGB');
is( $tuple->[0],           1, 'Red value is right');
is( $tuple->[1],          .1, 'green value is right');
is( $tuple->[2],           0, 'blue value is right');

$tuple = $convert->([.1, .2, .3], 'YUV', undef, 'YUV', [1, 0.1, 0]);
is( int @$tuple,           3, 'get normalized source values');
is( $tuple->[0],           1, 'Red value is right');
is( $tuple->[1],         -.4, 'green value is right');
is( $tuple->[2],         -.5, 'blue value is right');

$tuple = $convert->([0, 0.1, 1], 'CMY');
is( int @$tuple,           3, 'invert values');
is( $tuple->[0],           1, 'cyan value is right');
is( $tuple->[1],         0.9, 'magenta value is right');
is( $tuple->[2],           0, 'yellow value is right');

$tuple = $convert->([0, 0, 0], 'LAB');
is( ref $tuple,      'ARRAY', 'convert black to LAB (2 hop conversion)');
is( int @$tuple,           3, 'convert black to LAB (2 hop conversion)');
is( round_decimals( $tuple->[0], 5), 0, 'L value is right');
is( round_decimals( $tuple->[1], 5), 0, 'a value is right');
is( round_decimals( $tuple->[2], 5), 0, 'b value is right');

$tuple = $convert->([0, 0, 0], 'LAB', 1);
is( int @$tuple,           3, 'convert black to normal LAB');
is( round_decimals( $tuple->[0], 5),  0, 'L value is right');
is( round_decimals( $tuple->[1], 5), .5, 'a value is right');
is( round_decimals( $tuple->[2], 5), .5, 'b value is right');

$tuple = $convert->([1, 1/255, 0], 'LAB');
is( int @$tuple,           3, 'convert bright red to LAB');
is( round_decimals( $tuple->[0], 3), 53.264, 'L value is right');
is( round_decimals( $tuple->[1], 3), 80.024, 'a value is right');
is( round_decimals( $tuple->[2], 3), 67.211, 'b value is right');

$tuple = $convert->([1, 1/255, 0], 'LAB', 0 , 'XYZ', [0,0,0] );
is( int @$tuple,                      3, 'convert to LAB with original source in XYZ');
is( round_decimals( $tuple->[0], 5),  0, 'L value is right');
is( round_decimals( $tuple->[1], 5),  0, 'a value is right');
is( round_decimals( $tuple->[2], 5),  0, 'b value is right');

$tuple = $convert->([1, 1/255, 0], 'CIELCHab');
is( int @$tuple,           3, 'convert bright red to LCH (3 hop conversion)');
is( round_decimals( $tuple->[0],  3),  53.264, 'L value is right');
is( round_decimals( $tuple->[1],  3), 104.505, 'C value is right');
is( round_decimals( $tuple->[2],  3),  40.026, 'H value is right');

$tuple = $convert->([1, 1/255, 0], 'CIELCHab', 1);
is( int @$tuple,           3, 'convert bright red to normalized LCH');
is( round_decimals( $tuple->[0],  5), .53264, 'L value is right');
is( round_decimals( $tuple->[1],  5), .19389, 'C value is right');
is( round_decimals( $tuple->[2],  5), 0.11118, 'H value is right');

########################################################################
$tuple = $deconvert->( 'RGB', [0,1/255,1], );
is( ref $tuple,      'ARRAY', 'did minimal none deconversion');
is( int @$tuple,           3, 'RGB has 3 axis');
is( $tuple->[0],           0, 'red value is right');
is( $tuple->[1],           1, 'green value is right');
is( $tuple->[2],         255, 'blue value is right');

$tuple = $deconvert->( 'RGB', [0,1/255,1], 'normal');
is( int @$tuple,           3, 'wanted  normalized result');
is( $tuple->[0],           0, 'red value is right');
is( $tuple->[1],       1/255, 'green value is right');
is( $tuple->[2],           1, 'blue value is right');

$tuple = $deconvert->( 'CMY', [0, 0.1, 1] );
is( int @$tuple,           3, 'invert values from CMY');
is( $tuple->[0],         255, 'red value is right');
is( $tuple->[1],         230, 'green  value is right');
is( $tuple->[2],           0, 'blue value is right');

$tuple = $deconvert->( 'CMY', [0, 0.1, 1], 'normal' );
is( int @$tuple,           3, 'invert values from CMY');
is( $tuple->[0],           1, 'red value is right');
is( $tuple->[1],         0.9, 'green  value is right');
is( $tuple->[2],           0, 'blue value is right');

$tuple = $deconvert->('LAB', [0, 0.5, 0.5] );
is( int @$tuple,           3, 'convert black from LAB');
is( round_decimals( $tuple->[0], 5), 0, 'red value is right');
is( round_decimals( $tuple->[1], 5), 0, 'green value is right');
is( round_decimals( $tuple->[2], 5), 0, 'blue value is right');

$tuple = $deconvert->('LCH', [.53264, 104.505/539, 40.026/360], 1);
is( int @$tuple,           3, 'convert bright red from LCH');
is( round_decimals( $tuple->[0], 5), 1, 'L value is right');
is( round_decimals( $tuple->[1], 4), 0.0039, 'C value is right');
is( round_decimals( $tuple->[2], 5), 0, 'H value is right');

########################################################################
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

########################################################################
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
