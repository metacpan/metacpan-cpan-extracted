#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 93;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color qw/color/;

my $module = 'Graphics::Toolkit::Color';
my $red   = color('#FF0000');
my $blue  = color('#0000FF');
my $white = color('white');
my $black = color('black');

#### invert ############################################################
is( ref $white->invert('-'),                     '',  'need a valid name space to invert');
is( ref $white->invert( at => 'RGB'),            '',  'can not use invented arguments');
is( ref $white->invert(),                   $module,  'works without argument');
is( ref $white->invert(in => 'RGB'),        $module,  'can use "in" argument');
is( $white->invert()->name,                 'black',  'black is white inverted');
is( $white->invert('RGB')->name,            'black',  'explicit color space name works');
is( $white->invert(in => 'RGB')->name,      'black',  'named argument works');
is( $black->invert('RGB')->name,            'white',  'white is black inverted');
is( $blue->invert('RGB')->name,            'yellow',  'yellow is blue inverted');
is( $blue->invert('HSL')->name,              'gray',  'in HSL is gray opposite to any color');
is( $blue->invert('LAB')->name,                  '',  'LAB is not symmetrical');
is( $white->invert('HSL')->name,            'black',  'primary contrast works in HSL');
is( $white->invert('HWB')->name,            'black',  'primary contrast works in HWB');

#### set_value #########################################################
is( ref $white->set_value(),                             '',  'need some argument for "set_value"');
is( ref $white->set_value(ar => 3),                      '',  'reject invented axis names');
is( ref $white->set_value(r => 3, y => 1),               '',  'reject mixing axis frm different spaces');
is( ref $white->set_value( red => 1),               $module,  'accept real axis names');
is( ref $white->set_value( red => 1, in => 'RGB'),  $module,  'accept mixed arguments, axis name and space name');
my @values = $white->set_value( red => 1 )->values();
is( int @values,                                          3, 'got 3 values');
is( $values[0],                                           1, 'red value has the set number');
is( $values[1],                                         255, 'green value has the old number');
is( $values[2],                                         255, 'blue value has also the old number');
@values = $white->set_value( red => 1, in => 'RGB')->values();
is( int @values,                                          3, 'same like before, but tied color space');
is( $values[0],                                           1, 'red value has the set number');
is( $values[1],                                         255, 'green value has the old number');
is( $values[2],                                         255, 'blue value has also the old number');
@values = $white->set_value( r => 0, g => 22, b => 256)->values();
is( int @values,                                          3, 'use short axis names');
is( $values[0],                                           0, 'red value has the set number, zero');
is( $values[1],                                          22, 'green value has the set number');
is( $values[2],                                         255, 'blue has the clamped number, was too big');
is( $white->set_value( lightness => 0)->name,       'black', 'dimming down to black');
is( $white->set_value( blackness => 100)->name,     'black', 'works in HWB too');

#### add_value #########################################################
is( ref $white->add_value(),                               '',  'need some argument for "add_value"');
is( ref $white->add_value( bu => 3),                       '',  'reject invented axis names');
is( ref $white->add_value( blue => 3, 'a*' => 1),          '',  'reject mixing axis frm different spaces');
is( ref $white->add_value( blue => 3, in => 'LAB'),        '',  'blue is no axis in CIELAB');
is( ref $white->add_value( BLUE => 1),                $module,  'accept real axis names, even in upper case');
is( ref $white->add_value( Yellow => 1, in => 'CMY'), $module,  'accept mixed arguments, axis name and space name');
@values = $white->add_value( Yellow => 1)->values();
is( int @values,                                          3, 'added yellow by one');
is( $values[0],                                         255, 'red value has the old number');
is( $values[1],                                         255, 'green value has the old number');
is( $values[2],                                           0, 'blue value has the reduced number');
@values = $white->add_value( Yellow => 1, in => 'CMY')->values();
is( int @values,                                          3, 'named explicitly color space');
is( $values[0],                                         255, 'red value has the old number');
is( $values[1],                                         255, 'green value has the old number');
is( $values[2],                                           0, 'blue value has the reduced number');
@values = $white->add_value( Lightness => -1)->values(in => 'HSL');
is( int @values,                                          3, 'HSL has 3 values');
is( $values[0],                                           0, 'hue is zero');
is( $values[1],                                           0, 'saturation value is also zero');
is( $values[2],                                          99, 'lightness was reduced');
@values = $white->add_value( hue => 600, Lightness => +1)->values(in => 'HSL');
is( int @values,                                          3, 'changed two values at once');
is( $values[0],                                         240, 'hue was added and rotated into range');
is( $values[1],                                           0, 'saturation value is also zero');
is( $values[2],                                         100, 'lightness was raised and clamped back into range');

########################################################################
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
is( int @values,                                          3, 'HSL has three values');
is( $values[0],                                         120, 'hue is green (between white = red = 0 and blue)');
is( $values[1],                                          50, 'saturation is 50 since thite had none');
is( $values[2],                                          75, 'lightness is between 50 and 100');
@values = $white->mix( to => $blue, in => 'HSL', amount => 10)->values('HSL');
is( int @values,                                          3, 'only little blue this time');
is( $values[0],                                          24, 'hue redish');
is( $values[1],                                          10, 'saturation is 10 since thite had none');
is( $values[2],                                          95, 'lightness is from 100 - 10% toward 50');
@values = $white->mix( to => $blue, in => 'HSL', amount => 110)->values('HSL');
is( int @values,                                          3, 'using too much blue this time');
is( $values[0],                                         240, 'blue hue');
is( $values[1],                                         100, 'full saturation');
is( $values[2],                                          50, 'half lightness, like all fully saturated colors');
@values = $white->mix( to => [$blue, $black] )->values('RGB');
is( int @values,                                          3, 'mixing three colors, but actually only 2');
is( $values[0],                                           0, 'red is zero');
is( $values[1],                                           0, 'no green saturation');
is( $values[2],                                         128, 'half blue value');
@values = $white->mix( to => [$blue, $black], amount => [20, 10] )->values('RGB');
is( $values[0],                                         179, 'red value = 70% white');
is( $values[1],                                         179, 'green is same');
is( $values[2],                                         230, 'blue = 70% white + 20% blue');
@values = $white->mix( to => [$blue, $black], amount => [80, 20] )->values('RGB');
is( $values[0],                                           0, 'red value is zero = 80% blue + 20% black = 0 + 0');
is( $values[1],                                           0, 'green is same');
is( $values[2],                                         204, 'blue value is 80% blue + nothing from black');

exit 0;
