#!/usr/bin/perl
#
use v5.12;
use warnings;
use Test::More tests => 29;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color qw/color/;

my $red   = color('#FF0000');
my $blue  = color('#0000FF');
my $white = color('white');
my $black = color('black');

warning_like {$red->set()}           {carped => qr/need arguments as hash/},    "set method needs arguments";
warning_like {$red->set([1,2,3])}    {carped => qr/need arguments as hash/},    "input has to be a HASH not ARRAY";
warning_like {$red->set(fox => 4)}   {carped => qr/to any supported color/},    "no color value keys detected";

is( $black->set( blue => 255   )->name, 'blue', 'could set the blue value' );
is( $black->set({blue => 255} )->name,  'blue', 'could set the blue value with HASH syntax' );
is( $white->set(  r   => 0 )->name,     'aqua', 'could set red value via key shortcut' );
is( $white->set(  l   => 0 )->name,    'black', 'could set HSL value' );
is( $blue->values(in => 'HSL', as => 'hash')->{'saturation'},  100, 'blue has full saturation' );
is( $blue->set(  saturation => 50 )->values(in => 'HSL', as => 'hash')->{'saturation'},    50, 'could set it to half' );


warning_like {$red->add()}                       {carped => qr/need arguments as hash/}, "add method needs arguments";
warning_like {$red->add(r => 4, g => 2, t=> 3)}  {carped => qr/not correlate to any/},    "fantasy value keys detected";
warning_like {$red->add({r => 4, g => 2, t=> 3})}{carped => qr/not correlate to any/},    "fantasy value keys detected in hash syntax";

is( $black->add( blue => 255   )->name,                      'blue', 'could add the full blue value' );
is( $white->add( lightness => -100   )->name,               'black', 'subtract values via add' );
is( $white->add( red => 100   )->name,                      'white', 'values will be trimmed' );



is( $black->blend( with => $white )->name,                   'gray',   "blend black + white = gray");
is( $black->blend( with => $white, pos => 0 )->name,        'black',  "blend nothing, keep color");
is( $black->blend( with => $white, pos => 1 )->name,        'white',   "blend nothing, take c2");
is( $black->blend( with => $white, pos => 2 )->name,        'white',   "RGB limits kept");
is( $red->blend( with => 'blue')->name,                      'lime',   "blending with name");
is( $blue->blend( with => 'red')->name,                      'lime',   "flip the ingredients");
is( $red->blend( with => 'blue', in => 'RGB')->name,       'purple',   "blending in RGB");
is( $red->blend( with => 'blue', in => 'CMYK')->name,      'purple',   "blending in CMYK");
is( $red->blend( with => '#0000ff')->name,                   'lime',   "blending with hex def");
is( $red->blend( with => [0,0,255])->name,                   'lime',   "blending with array ref color def");
my $purple = $red->blend( with => {C => 1, M =>1, Y =>0}, in =>'CMY');
my @rgb = $purple->values('RGB');
is( $rgb[0],                                                    128,   "blending with RGB hash ref color def in CMY, red value");
is( $rgb[1],                                                      0,   "blending with RGB hash ref color def in CMY, green value");
is( $rgb[2],                                                    128,   "blending with RGB hash ref color def in CMY, blue value");
is( $red->blend( with => {H=> 240, S=> 100, L=>50}, in => 'RGB')->name,'purple',   "blending with HSL hash in RGB");

#     'fuchsia'             => [ 255,   0, 255, 300, 100,  50 ],
#     'lime'                => [   0, 255,   0, 120, 100,  50 ],
#     'purple'              => [ 128,   0, 128, 300, 100,  25 ],

exit 0;
