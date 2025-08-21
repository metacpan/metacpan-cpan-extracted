#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 95;
BEGIN { unshift @INC, 'lib', '../lib'}
use Graphics::Toolkit::Color qw/color/;

my $module  = 'Graphics::Toolkit::Color';
my $red     = color('#FF0000');
my $blue    = color('#0000FF');
my $white   = color('white');
my $black   = color('black');
my $midblue = color(43, 52, 242);
my @colors;
my @values;
#### complement ########################################################
unlike( $blue->complement(),                                   qr/GTC method/,  'complement methods works without argument');
like( $blue->complement( heps => 3),                           qr/GTC method/,  'reject invented argument');
like( $blue->complement('der'),                                qr/GTC method/,  'only argument has to be numeric');
like( $blue->complement( steps =>'der'),                       qr/GTC method/,  'named argument "steps" still has to be numeric');
like( $blue->complement( steps =>2, tilt => '-'),              qr/GTC method/,  'named argument "tilt" still has to be numeric');
like( $blue->complement( target => []),                        qr/GTC method/,  'named argument "target" got wrong reference type');
like( $blue->complement( target => {hue => 2, gamma => 2}),    qr/GTC method/,  'named argument "target" got HASH ref with bad axis name');

@colors = $red->complement( );
is( int @colors,                        1,    'default is THE complement');
is( $colors[0]->name,              'cyan',    'which got computed correctly');
@colors = $red->complement( steps => 1);
is( int @colors,                        1,    'same with named argument');
is( $colors[0]->name,              'cyan',    'result still good');
@colors = $red->complement( steps => 3);
is( int @colors,                        3,    'got triadic colors');
is( $colors[0]->name,              'lime',    'first is full green (lime)');
is(($colors[0]->values('HSL'))[0],    120,    'green has hue of 120');
is( $colors[1]->name,              'blue',    'second is blue');
is(($colors[1]->values('HSL'))[0],    240,    'blue has hue of 240');
is( $colors[2]->name,               'red',    'third is red');
is(($colors[2]->values('HSL'))[0],      0,    'red has hue of 0');
@colors = $red->complement( steps => 3, tilt => 1 );
is( int @colors,                        3,    'got split complement');
@values = $colors[0]->values('HSL');
is( @values,                            3,    'first color in HSL');
is( $values[0],                       100,    '0 + 1 - 4/9 of 180 hue degree');
is( $values[1],                       100,    'full saturation');
is( $values[2],                        50,    'half lightness');
@values = $colors[1]->values('HSL');
is( $values[0],                       260,    '0 + 1 - 4/9 of 180 hue degree');

@colors = $red->complement( steps => 4, tilt => 1.585, target => {h => -10, s => 20, l => 30} );
is( @colors,                            4,    'computed 4 complements with a moved target and split comp tilt');
@values = $colors[3]->values('HSL');
is( $values[0],                         0,    'fourth color is invocant, normal red');
is( $values[1],                       100,    'full saturation');
is( $values[2],                        50,    'half lightness');
@values = $colors[1]->values('HSL');
is( $values[0],                       170,    'complement taret has user set values');
is( $values[1],                       100,    'full saturation, was clamped');
is( $values[2],                        80,    'half lightness, was added');
@values = $colors[0]->values('HSL');
is( $values[0],                       142,    'hue of first color seem right');
is( $values[1],                       100,    'saturation is constant');
is( $values[2],                        75,    'lightness, in between on tilted circle');
@values = $colors[2]->values('HSL');
is( $values[0],                       202,    'hue of third color seem right');
is( $values[1],                       100,    'saturation is constant');
is( $values[2],                        75,    'lightness, same as first');

#### gradient ##########################################################
like( $white->gradient(),                                       qr/GTC method/,  'gradient method needs arguments');
like( $white->gradient('s'),                                    qr/GTC method/,  'only argument has to be a color');
unlike( $white->gradient('red'),                                qr/GTC method/,  'only argument works');
unlike( $white->gradient(to => 'red'),                          qr/GTC method/,  'as named also');
like( $white->gradient(to => ['red','no']),                     qr/GTC method/,  'ARRAY contained one bad color definition');
like( $white->gradient(to => 'red', der => 1),                  qr/GTC method/,  'reject invented args');
like( $white->gradient(to => 'red', in => 'house'),             qr/GTC method/,  'reject invented name spaces');
like( $white->gradient(to => 'red', tilt => 'house'),           qr/GTC method/,  'argument "tilt" has to be numeric');
like( $white->gradient(to => 'red', steps => 'house'),          qr/GTC method/,  'argument "steps" has to be numeric');

@colors = $red->gradient( 'green');
is( int @colors,                       10,    'default for steps is 10');
is( $colors[0]->name,               'red',    'first color is red');
is( $colors[9]->name,             'green',    'last color is green');
@colors = $red->gradient( to => 'green');
is( int @colors,                       10,    'default for steps is 10');
is( $colors[0]->name,               'red',    'first color is red');
is( $colors[9]->name,             'green',    'last color is green');
@colors = $blue->gradient( to => 'red', steps => 3 );
is( int @colors,                        3,    'argument steps works');
is( $colors[1]->name,            'purple',    'got mixed color in the middle');
@colors = $blue->gradient( to => ['white','red', 'blue'], steps => 7 );
is( $colors[5]->name,            'purple',    'got mixed inside cmlex rainbow');
@colors = $blue->gradient( to => 'red', steps => 3, tilt => 1 );
@values = $colors[1]->values();
is( @values,                            3,    'center color in tilted gradient');
is( $values[0],                        64,    'red value is right');
is( $values[1],                         0,    'green value is right');
is( $values[2],                       191,    'blue value is right');

#### cluster ###########################################################
like( $white->cluster(),                                        qr/GTC method/,  'cluster method needs arguments');
like( $white->cluster(1),                                       qr/GTC method/,  'one is not enough');
like( $white->cluster(radius => 2),                             qr/GTC method/,  'only radius is not enough');
like( $white->cluster(distance => 2),                           qr/GTC method/,  'only distance is not enough');
unlike( $white->cluster(radius => 2, distance => 2),            qr/GTC method/,  'need both');
like( $white->cluster(radius => 2, distance => 2, in => 'CMA'), qr/GTC method/,  'need real space name');
like( $white->cluster(radius => 1, distance => '-'),            qr/GTC method/,  "distance has to be a number");
like( $white->cluster(radius => 'd', distance => 2),            qr/GTC method/,  "radius has to be a number");
like( $white->cluster(radius => [1,2,3], distance => 2, in => 'CMYK'),     qr/GTC method/,  "radius tuple too short");
like( $white->cluster(radius => ['e',1,2,3], distance => 2, in => 'CMYK'), qr/GTC method/,  "radius tuple has to be number only");
unlike( $white->cluster(radius => [0,1,2,3], distance => 2, in => 'CMYK'), qr/GTC method/,  "radius tuple in solng enough");
like( $white->cluster(radius => 5, distance => 2, in => 'CMYK'),           qr/GTC method/,  "CMYK doesn't work with cuboctahedral packing");
like( $white->cluster(radius => 0, distance => 0),                         qr/GTC method/,  "distance has to be positive");
like( $white->cluster(radius => 1, distance => 1, ar => 2),                qr/GTC method/,  "reject invented arguments");
like( $white->cluster(radius => 1, distance => 1, 'ar'),                   qr/GTC method/,  "odd number of arguments");

@colors = $midblue->cluster( radius => 2, distance => 2 );
is( int @colors,                       13,    'computed smallest ball shaped cluster in RGB');
@values = $colors[1]->values();
is( @values,                            3,    'center color is on pos one');
is( $values[0],                        43,    'red value is right');
is( $values[1],                        52,    'green value is right');
is( $values[2],                       242,    'blue value is right');
@values = $colors[0]->values();
is( $values[0],                        41,    'first color has less red');
is( $values[2],                       242,    'blue is same as center');
@values = $colors[2]->values();
is( $values[0],                        45,    'third color has more red');
@values = $colors[12]->values();
is( $values[0],                        42,    'red value is right (was rounded up to same)');
is( $values[1],                        51,    'green value is right');
is( $values[2],                       241,    'blue value is right (1.4 less but rounded up)');

@colors = $midblue->cluster( radius => [1,1,1], distance => 1, in => 'RGB');
is( int @colors,                       27,    'computed tiny cuboid cluster with 27 colors');
@values = $colors[0]->values();
is( int @values,                        3,    'got first color in min corner');
is( $values[0],                        42,    'red value is right');
is( $values[1],                        51,    'green value is right');
is( $values[2],                       241,    'blue value is right');
@values = $colors[26]->values();
is( int @values,                        3,    'got last color in max corner');
is( $values[0],                        44,    'red value is right');
is( $values[1],                        53,    'green value is right');
is( $values[2],                       243,    'blue value is right');

@colors = $white->cluster( radius => [1,1,1], distance => 1, in => 'HSL' );
is( int @colors,                       12,    'cluster edging on roof of HSL space');

exit 0;
