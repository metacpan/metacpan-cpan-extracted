#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 62;
use Graphics::Toolkit::Color qw/color/;

my $module = 'Graphics::Toolkit::Color';
my $red   = color('#FF0000');
my $blue  = color('#0000FF');
my $white = color('white');
my $black = color('black');
my $nice_blue = color(10,20,200);

#### apply gamma #######################################################
my @values = $red->apply( gamma => 2.4 )->values();
is_tuple( \@values, [255, 0, 0], [qw/red green blue/], 'correct red with gamma of 2.4');

@values = $nice_blue->apply( gamma => 0.4 )->values();
is_tuple( \@values, [ 70, 92, 231], [qw/red green blue/], 'correct nice blue with gamma of 0.4');
@values = $nice_blue->apply( gamma => {cyan => 2, m => 0.5}, in => 'CMY' )->values();
is_tuple( \@values, [ 20, 10, 200], [qw/red green blue/], 'correct nice blue with special gamma per axis');

#### set_value #########################################################
is( ref $white->set_value(),                             '',  'need some argument for "set_value"');
is( ref $white->set_value(ar => 3),                      '',  'reject invented axis names');
is( ref $white->set_value(r => 3, y => 1),               '',  'reject mixing axis frm different spaces');
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
is( ref $white->add_value(),                               '',  'need some argument for "add_value"');
is( ref $white->add_value( bu => 3),                       '',  'reject invented axis names');
is( ref $white->add_value( blue => 3, 'a*' => 1),          '',  'reject mixing axis frm different spaces');
is( ref $white->add_value( blue => 3, in => 'LAB'),        '',  'blue is no axis in CIELAB');
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
is( ref $white->mix(),                                     '',  'need some argument for "mix"');
is( ref $white->mix( 'ellow'),                             '',  'reject invented color name');
is( ref $white->mix( to => 'ellow'),                       '',  'reject invented color name as named argument');
is( ref $white->mix( to => 'blue', 'a*' => 1),             '',  'reject invented argument names');
is( ref $white->mix( to => 'blue', 'in' => 'HS'),          '',  'reject invented color space name');
is( ref $white->mix( to => 'blue', amount => []),          '',  'amount arg is ARRAY and colors not');
is( ref $white->mix( to => ['blue'], amount => [1,2]),     '',  'amount and to arg ARRAY have different length');
is( ref $white->mix( 'black'),                        $module,  'one argument mode');
is( ref $white->mix( ['black']),                      $module,  'one argument mode, but ARRAY');
is( ref $white->mix( ['black', $blue]),               $module,  'one argument mode, but longer ARRAY');
is( ref $white->mix( to => 'black'),                  $module,  'one named argument mode');
is( ref $white->mix( to => ['black']),                $module,  'one named argument as ARRAY');
is( ref $white->mix( to => ['black', 'blue']),        $module,  'one named argument as longer ARRAY');

is($white->mix( $black)->name,                       'gray', 'grey is the mix between black and white');
is($white->mix( to => 'black')->name,                'gray', 'use color constant and named argument');
is($white->mix( to => 'black', amount => 50)->name,  'gray', 'use also amount argument');
is($white->mix( to => 'black', amount => 20)->name,'gray80', 'use different amount');

@values = $white->mix( to => $blue, in => 'HSL')->values('HSL');
is_tuple( \@values, [ 120, 50, 75], [qw/hue saturation lightness/], 'mix white and blue 1:1 in HSL');
@values = $white->mix( to => $blue, in => 'HSL', amount => 10)->values('HSL');
is_tuple( \@values, [ 24, 10, 95], [qw/hue saturation lightness/], 'mix white and blue 9:1 in HSL');
@values = $white->mix( to => $blue, in => 'HSL', amount => 110)->values('HSL');
is_tuple( \@values, [ 240, 100, 50], [qw/hue saturation lightness/], 'mix white and 110% blue HSL = blue');
@values = $white->mix( to => [$blue, $black] )->values('RGB');
is_tuple( \@values, [ 85, 85, 170], [qw/red green blue/], 'mix white with blue and black');
@values = $white->mix( to => [$blue, $black], amount => [20, 10] )->values('RGB');
is_tuple( \@values, [ 179, 179, 230], [qw/red green blue/], 'mix white with blue (20%) and black(10%)');
@values = $white->mix( to => [$blue, $black], amount => [80, 20] )->values('RGB');
is_tuple( \@values, [ 0, 0, 204], [qw/red green blue/], 'mix white with blue (80%) and black(20%) - no white influence left');
@values = $white->mix( to => [$blue, $black], amount => [90, 30] )->values('RGB');
is_tuple( \@values, [ 0, 0, 191], [qw/red green blue/], 'mix white with blue (90%) and black(30%) - still no white');

#### invert ############################################################
is( ref $white->invert('-'),                     '',  'need a valid name space to invert');
is( ref $white->invert( at => 'RGB'),            '',  'can not use invented arguments');
is( ref $white->invert(),                   $module,  'works without argument');
is( ref $white->invert(in => 'RGB'),        $module,  'can use "in" argument');
is( $white->invert()->name,                 'black',  'black is white inverted');
is( $white->invert(only => 'b')->name,     'yellow',  'you get yellow if you invert only blue axis');
is( $white->invert('RGB')->name,            'black',  'explicit color space name works');
is( $white->invert(in => 'RGB')->name,      'black',  'named argument "in" works');
is( $black->invert('RGB')->name,            'white',  'white is black inverted');
is( $black->invert(only => ['red', 'green'])->name,     'yellow',  'you get yellow if you invert red and green');
is( $blue->invert('RGB')->name,            'yellow',  'yellow is blue inverted');
is( $blue->invert('HSL')->name,              'gray',  'in HSL is gray opposite to any color');
is( $blue->invert('LAB')->name,                  '',  'LAB is not symmetrical');
is( $white->invert('HSL')->name,            'black',  'primary contrast works in HSL');
is( $white->invert('HWB')->name,            'black',  'primary contrast works in HWB');

exit 0;
