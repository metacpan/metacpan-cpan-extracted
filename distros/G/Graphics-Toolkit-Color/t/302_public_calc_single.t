#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 64;
use Test::Warn;
use Graphics::Toolkit::Color qw/color/;

my $module = 'Graphics::Toolkit::Color';
my $red   = color('#FF0000');
my $blue  = color('#0000FF');
my $white = color('white');
my $black = color('black');
my $nice_blue = color(10, 20, 200);

#### apply gamma #######################################################
my @values = $red->apply( gamma => 2.4 )->values('LinearRGB');
is_tuple( \@values, [1, 0, 0], [qw/red green blue/], 'gamma correction does not touch max or min values');

@values = $nice_blue->apply( gamma => 1 )->values(in => 'LinearRGB', precision => 7);
is_tuple( \@values, [ 0.0030353, 0.0069954, 0.5775804], [qw/red green blue/], 'gamma correction with a gamma of 1 does not touch values');

@values = $nice_blue->apply( gamma => 0.4 )->values(in => 'LinearRGB', precision => 7);
is_tuple( \@values, [ 0.0983737, 0.1373806, 0.8028696], [qw/red green blue/], 'gamma correct nice blue with gamma of 0.4');

@values = $nice_blue->apply( gamma => {cyan => 2, m => 0.5}, in => 'CMY' )->values();
is_tuple( \@values, [ 20, 10, 200], [qw/red green blue/], 'correct nice blue with special gamma per axis');

#### set_value #########################################################
warning_like { $white->set_value()}  {carped => qr/The method "set_value"/}, 'method "set_value" needs arguments';
warning_like { $white->set_value(ar => 3)}  {carped => qr/not correlate to any supported color space/}, 'reject invented axis names';
warning_like { $white->set_value(ar => 3, y => 1)}  {carped => qr/correlate to any supported color space/}, 'reject mixing axis from different spaces';
is( ref $white->set_value( red => 1),               $module,  'accept real axis names');
is( ref $white->set_value( red => 1, in => 'RGB'),  $module,  'accept mixed arguments, axis name and space name');
@values = $white->set_value( red => 1 )->values();
is_tuple( \@values, [ 1, 255, 255], [qw/red green blue/], 'white with a set red value defaults to RGB');
@values = $white->set_value( red => 1, in => 'RGB')->values();
is_tuple( \@values, [ 1, 255, 255], [qw/red green blue/], 'white with a set red value in RGB');
@values = $white->set_value( r => 0, g => 22, b => 256)->values();
is_tuple( \@values, [ 0, 22, 255], [qw/red green blue/], 'white with a set blue value');
is( $white->set_value( lightness => 0)->name,       'black', 'dimming down to black');
is( $white->set_value( blackness => 100)->name,      'gray', 'adding full blackness to white = gray');

#### add_value #########################################################
warning_like { $white->add_value()}  {carped => qr/The method "add_value"/}, 'method "add_value" needs arguments';
warning_like { $white->add_value(bu => 3)}  {carped => qr/not correlate to any supported color space/}, 'reject invented axis names';
warning_like { $white->add_value( blue => 3, 'a*' => 1)}  {carped => qr/correlate to any supported color space/}, 'reject mixing axis from different spaces';
warning_like { $white->add_value( blue => 3, in => 'LAB')}  {carped => qr/do not correlate to the selected color space/}, 'axis names are not from demanded space';
is( ref $white->add_value( BLUE => 1),                $module,  'accept real axis names, even in upper case');
is( ref $white->add_value( Yellow => 1, in => 'CMY'), $module,  'accept mixed arguments, axis name and space name');
@values = $white->add_value( Yellow => 1)->values();
is_tuple( \@values, [ 255, 255, 0], [qw/red green blue/], 'remove all blue by adding all yellow in CMY');
@values = $white->add_value( Yellow => 1, in => 'CMY')->values();
is_tuple( \@values, [ 255, 255, 0], [qw/cyan magenta yellow/], 'same but choose CMY explicitly');
@values = $white->add_value( Lightness => -1)->values(in => 'HSL');
is_tuple( \@values, [ 0, 0, 99], [qw/hue saturation lightness/], 'same but in HSL');
@values = $white->add_value( hue => 600, Lightness => +1)->values(in => 'HSL');
is_tuple( \@values, [ 240, 0, 100], [qw/hue saturation lightness/], 'add HSL values that get clamped into shape');

#### mix ###############################################################
warning_like { $white->mix()}    {carped => qr/Argument 'to' is missing/}, 'method "mix" needs arguments';
warning_like { $white->mix('ellow')}    {carped => qr/Target color definition/}, 'reject invented color name as destination color';
warning_like { $white->mix(to => 'ellow')}   {carped => qr/Could not deformat color/}, 'reject invented color name as named argument';
warning_like { $white->mix(to => 'blue', 'a*' => 1)}   {carped => qr/Inserted unknown argument/}, 'reject invented argument names';
warning_like { $white->mix(to => 'blue', 'in' => 'HS')}   {carped => qr/is an unknown color space/}, 'reject invented color space name';
warning_like { $white->mix(to => 'blue', by => [])}   {carped => qr/value for every color/}, 'argument "by" got empty ARRAY';
warning_like { $white->mix(to => ['blue'], by => [1,2])}   {carped => qr/value for every color/}, 'argument "by" got ARRAY with too many values';
is( ref $white->mix( 'black'),                        $module,  'one argument mode');
is( ref $white->mix( ['black']),                      $module,  'one argument mode, but ARRAY');
is( ref $white->mix( ['black', $blue]),               $module,  'one argument mode, but longer ARRAY');
is( ref $white->mix( to => 'black'),                  $module,  'one named argument mode');
is( ref $white->mix( to => ['black']),                $module,  'one named argument as ARRAY');
is( ref $white->mix( to => ['black', 'blue']),        $module,  'one named argument as longer ARRAY');

is($white->mix( $black )->name,	                   'gray39', 'grey is the mix between black and white in OKLAB');
is($white->mix( to => 'black', in => 'RGB' )->name,  'gray', 'use color constant and named argument');
is($white->mix( to => 'black', amount => .5, in => 'RGB')->name,  'gray', 'use also amount argument');
is($white->mix( to => 'black', amount => .2, in => 'RGB')->name,'gray80', 'use different amount');

@values = $white->mix( to => $blue, in => 'HSL')->values('HSL');
is_tuple( \@values, [ 120, 50, 75], [qw/hue saturation lightness/], 'mix white and blue 1:1 in HSL');
@values = $white->mix( to => $blue, in => 'HSL', amount => 10)->values('HSL');
is_tuple( \@values, [ 24, 10, 95], [qw/hue saturation lightness/], 'mix white and blue 9:1 in HSL');
@values = $white->mix( to => $blue, in => 'HSL', amount => 110)->values('HSL');
is_tuple( \@values, [ 240, 100, 50], [qw/hue saturation lightness/], 'mix white and 110% blue HSL = blue');
@values = $white->mix( to => [$blue, $black], in => 'RGB' )->values('RGB');
is_tuple( \@values, [ 85, 85, 170], [qw/red green blue/], 'mix white with blue and black');
@values = $white->mix( to => [$blue, $black], amount => [20, 10], in => 'RGB' )->values('RGB');
is_tuple( \@values, [ 179, 179, 230], [qw/red green blue/], 'mix white with blue (20%) and black(10%)');
@values = $white->mix( to => [$blue, $black], amount => [80, 20], in => 'RGB' )->values('RGB');
is_tuple( \@values, [ 0, 0, 204], [qw/red green blue/], 'mix white with blue (80%) and black(20%) - no white influence left');
@values = $white->mix( to => [$blue, $black], amount => [90, 30], in => 'RGB' )->values('RGB');
is_tuple( \@values, [ 0, 0, 191], [qw/red green blue/], 'mix white with blue (90%) and black(30%) - still no white');

#### invert ############################################################
warning_like { $white->invert('-')}    {carped => qr/that contains the axes/}, 'method "invert" needs an axis name as default argument';
warning_like { $white->invert( at => 'RGB')}  {carped => qr/Inserted unknown argument/}, 'reject invented argument names';
is( ref $white->invert(),                   $module,  'works without argument');
is( ref $white->invert(in => 'RGB'),        $module,  'can use "in" argument');
is( $white->invert()->name,                 'black',  'black is white inverted');
is( $white->invert('red')->name,             'cyan',  'cyan is result when taking white and inverting only the red axis');
is( $white->invert(only => 'b')->name,     'yellow',  'you get yellow if you invert only blue axis');
is( $white->invert(in => 'RGB')->name,      'black',  'invert listens to explicit color space argument');
is( $black->invert(only => 'green', in => 'RGB')->name, 'lime',  'named arguments only and "in" work together');
is( $black->invert(only => [qw/g b/], in => 'RGB')->name, 'cyan',  'invert values on two selected axes (short names)');

is( $black->invert(only => ['red', 'green'], in => 'RGB')->name,     'yellow',  'use long axes names');
is( $blue->invert(in => 'RGB')->name,      'yellow',  'yellow is blue inverted');
is( $blue->invert(in => 'HSL')->name,        'gray',  'in HSL is gray opposite to any color');
is( $blue->invert(in => 'LAB')->name,            '',  'LAB is not symmetrical');
is( $white->invert( in => 'HSL')->name,     'black',  'primary contrast works in HSL');
is( $white->invert( in => 'HWB')->name,     'black',  'primary contrast works in HWB');

exit 0;
