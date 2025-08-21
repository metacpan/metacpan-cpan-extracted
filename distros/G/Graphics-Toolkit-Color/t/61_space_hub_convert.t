#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 79;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color::Space::Util 'round_decimals';
use Graphics::Toolkit::Color::Space::Hub;

my $convert       = \&Graphics::Toolkit::Color::Space::Hub::convert;
my $deconvert     = \&Graphics::Toolkit::Color::Space::Hub::deconvert;

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

exit 0;
