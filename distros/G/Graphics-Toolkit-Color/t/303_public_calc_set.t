#!/usr/bin/perl

use v5.12;
use warnings;
use lib 'lib', '../lib/', '.', './t';
use Test::Color;
use Test::More tests => 92;
use Test::Warn;
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
unlike( $blue->complement(),                                   qr/GTC method/,  'method "complement" works without argument');
warning_like { $blue->complement( heps => 3) }    {carped => qr/Inserted unknown argument/}, 'method "complement" rejects invented argument names';
warning_like { $blue->complement( 'der') }        {carped => qr/argument "steps" has to be a number/}, 'default has to be numeric (steps)';
warning_like { $blue->complement( steps =>'der')} {carped => qr/argument "steps" has to be a number/}, 'named argument "steps" still has to be numeric';
warning_like { $blue->complement( tilt => '-') }  {carped => qr/argument "tilt" has to be a number/}, 'argument "tilt" has to be als numeric';
warning_like { $blue->complement( skew => '-') }  {carped => qr/argument "skew" has to be a number/}, 'argument "skew" has to be als numeric';
warning_like { $blue->complement( target => []) } {carped => qr/"target" has to be a HASH ref/}, 'argument "target" got wrong reference type';
warning_like { $blue->complement( target => {hue => 2, gamma => 2}) } {carped => qr/HASH keys that do not fit HSL/}, 'argument "target" got HASH ref with bad axis name';

@colors = $red->complement( in => 'HSL' );
is( int @colors,                        1,    'default is THE complement');
is( $colors[0]->name,              'cyan',    'which got computed correctly');
@colors = $red->complement( in => 'HSL', steps => 1);
is( int @colors,                        1,    'same with named argument');
is( $colors[0]->name,              'cyan',    'result still good');
@colors = $red->complement( in => 'HSL', steps => 3);
is( int @colors,                        3,    'got triadic colors');
is( $colors[0]->name,              'lime',    'first is full green (lime)');
is(($colors[0]->values('HSL'))[0],    120,    'green has hue of 120');
is( $colors[1]->name,              'blue',    'second is blue');
is(($colors[1]->values('HSL'))[0],    240,    'blue has hue of 240');
is( $colors[2]->name,               'red',    'third is red');
is(($colors[2]->values('HSL'))[0],      0,    'red has hue of 0');

@colors = $red->complement( in => 'HSL', steps => 3, tilt => 1 );
is( int @colors,                        3,    'got split complement');
@values = $colors[0]->values('HSL');
is_tuple( \@values, [ 100, 100, 50], [qw/hue saturation lightness/], 'first complement of red with tilt is green');
@values = $colors[1]->values('HSL');
is_tuple( \@values, [ 260, 100, 50], [qw/hue saturation lightness/], 'second complement of red with tilt is blue');

@colors = $red->complement( in => 'HSL', steps => 4, tilt => 1.585, target => {h => -10, s => 20, l => 30} );
is( @colors,                            4,    'computed 4 complements with a moved target and split comp tilt');
@values = $colors[0]->values('HSL');
is_tuple( \@values, [ 142, 100, 75], [qw/hue saturation lightness/], 'first complement of red tilt and with complex target');
@values = $colors[1]->values('HSL');
is_tuple( \@values, [ 170, 100, 80], [qw/hue saturation lightness/], 'second complement of red tilt and with complex target');
@values = $colors[2]->values('HSL');
is_tuple( \@values, [ 202, 100, 75], [qw/hue saturation lightness/], 'third complement of red tilt and with complex target');
@values = $colors[3]->values('HSL');
is_tuple( \@values, [   0, 100, 50], [qw/hue saturation lightness/], 'fourth complement of red tilt and with complex target');

#### analogous #########################################################
warning_like { $blue->analogous() }     {carped => qr/Argument 'to' is missing/}, 'method "analogous" needs arguments';
@colors = $blue->analogous( '#0000EE');
is( int @colors,                        4,    'computed default amount of analogous colors');
is( ref $colors[0],               $module,    'first result is a color');
@values = $colors[0]->values('RGB');
is_tuple( \@values, [ 0, 0, 255], [qw/red green blue/], 'first of analogous colors is the given one');
is( ref $colors[1],               $module,    'second result is a color');
@values = $colors[1]->values('RGB');
is_tuple( \@values, [ 0, 0, 238], [qw/red green blue/], 'second of analogous colors is the target');
is( ref $colors[2],               $module,    'third result is a color');
@values = $colors[2]->values('RGB');
is_tuple( \@values, [ 0, 0, 221], [qw/red green blue/], 'third of analogous colors is computed');
is( ref $colors[3],               $module,    'fourth result is a color');
@values = $colors[3]->values('RGB');
is_tuple( \@values, [ 0, 0, 204], [qw/red green blue/], 'fourth of analogous colors is computed too');
@colors = $blue->analogous( to => 'red'); # using named arg
is( int @colors,                        2,    'computing analogous colors stopped after minimum');
@colors = $blue->analogous( to => '#0000EE', steps => 3, tilt => 1);
is( int @colors,                        3,    'computed the requested amount of analogous colors');
is( ref $colors[2],               $module,    'third result is a color');
@values = $colors[2]->values('RGB');
is_tuple( \@values, [ 0, 0, 204], [qw/red green blue/], 'third of analogous colors is computed with right tilt');
warning_like { $blue->analogous( to => 'red', with => 'power')}  {carped => qr/Inserted unknown argument/}, 'method "analogous" rejects invented argument names';
warning_like { $blue->analogous(  to => 'red', steps =>'der')} {carped => qr/argument "steps" has to be a number/}, 'named argument "steps" still has to be numeric';
warning_like { $blue->analogous(  to => 'red', tilt => '-') }  {carped => qr/"tilt" has to be a number/}, 'argument "tilt" has to be als numeric';

#### gradient ##########################################################
warning_like { $white->gradient() }     {carped => qr/Argument 'to' is missing/}, 'method "gradient" needs arguments';
warning_like { $white->gradient('s') }     {carped => qr/contains malformed color definition/}, 'default argument has to be a color';
@colors = $white->gradient('red');
is( int @colors,                        10,    'computed default amount of gradient colors');
@colors = $white->gradient(to => 'red');
is( int @colors,                        10,    'argument "to" works too as named arg');
is( ref $colors[0],               $module,    'first result is a color');
is( ref $colors[9],               $module,    'last result is a color');
warning_like { $white->gradient(to => ['red','no']) }  {carped => qr/contains malformed color definition: no!/}, 'argument "to" got ARRAY with one bad color definition';
warning_like { $blue->analogous(to => 'red', der => 1)}  {carped => qr/Inserted unknown argument/}, 'method "gradient" rejects bad argument names';
warning_like { $blue->analogous(to => 'red', in => 'house')}  {carped => qr/HOUSE is an unknown color space/}, 'method "gradient" reject bad color space name';
warning_like { $blue->analogous(to => 'red', tilt => 'house')}  {carped => qr/argument "tilt" has to be a number/}, 'method "gradient" argument "tilt" has to be numeric';
warning_like { $blue->analogous(to => 'red', steps => 'house')}  {carped => qr/argument "steps" has to be a number/}, 'method "gradient" argument "steps" has to be numeric';

@colors = $red->gradient( 'green');
is( int @colors,                       10,    'default for steps is 10');
is( $colors[0]->name,               'red',    'first color is red');
is( $colors[9]->name,             'green',    'last color is green');
@colors = $red->gradient( to => 'green');
is( int @colors,                       10,    'default for steps is 10');
is( $colors[0]->name,               'red',    'first color is red');
is( $colors[9]->name,             'green',    'last color is green');
@colors = $blue->gradient( to => 'red', steps => 3, in => 'RGB' );
is( int @colors,                        3,    'argument steps works');
is( $colors[1]->name,            'purple',    'got mixed color in the middle');
@colors = $blue->gradient( to => ['white','red', 'blue'], steps => 7, in => 'RGB' );
is( int @colors,                        7,    'created seven colors');
is( $colors[5]->name,            'purple',    'got mixed inside cmlex rainbow');
@colors = $blue->gradient( to => 'red', steps => 3, tilt => 1, in => 'RGB' );
@values = $colors[1]->values();
is_tuple( \@values, [   64, 0, 191], [qw/red green blue/], 'center color in tilted gradient');

#### cluster ###########################################################
warning_like { $white->cluster() }     {carped => qr/Argument 'radius' is missing/}, 'method "cluster" needs arguments';
warning_like { $white->cluster(1) }     {carped => qr/please use key value pairs as arguments/}, 'method "cluster" has no default argument';
warning_like { $white->cluster(radius => 2) }  {carped => qr/Argument 'minimal_distance' is missing/}, 'only named argument "radius" is not enoug"';
warning_like { $white->cluster(minimal_distance => 2) }  {carped => qr/Argument 'radius' is missing/}, 'only named argument "minimal_distance" is not enoug"';

@colors = $white->cluster(radius => 2, minimal_distance => 2);
is( ref $colors[0],               $module,    '"radius" and "minimal_distance" are required arguments');
@colors = $white->cluster(r => 2, min_d => 2);
is( ref $colors[0],               $module,    'works also with "r" and "min_d" short aliases');

warning_like { $white->cluster(r => 2, min_d => 2, in => 'CMA') }  {carped => qr/CMA is an unknown color space/}, 'argument "in" needs a real space name';
warning_like { $white->cluster(r => 2, min_d => '-') }  {carped => qr/ has to be a number greater zero/}, 'argument "minimal_distance" needs to be a number';
warning_like { $white->cluster(r => 5, min_d => 0) }  {carped => qr/has to be a number greater zero!/}, "'minimal_distance' has to be positive";
warning_like { $white->cluster(r => '-', min_d => 2) }  {carped => qr/Argument "radius" has to be a non-negative number/}, 'argument "radius" needs to be a number';
warning_like { $white->cluster(r => -1, min_d => 0.1) }  {carped => qr/"radius" has to be a non-negative number/}, "'radius' can not be negative";
warning_like { $white->cluster(r => [2,2,2], min_d => 2, in => 'CMYK') }  {carped => qr/for each space axis a radius/}, 'tuple for argument "radius" has not enough elements for CMYK space';
warning_like { $white->cluster(r => ['e',2,2,2], min_d => 2, in => 'CMYK') }  {carped => qr/for each space axis a radius/}, 'radius tuple has to be number only';

@colors = $white->cluster(r => [0,1,2,3], min_d => 2, in => 'CMYK');
is( ref $colors[0],               $module,    'radius tuple has right length');
warning_like { $white->cluster(r => 5, min_d => 2, in => 'CMYK') }  {carped => qr/Ball shaped cluster works only in spaces with three dimensions/}, "CMYK doesn't work with cuboctahedral packing";
warning_like { $white->cluster(r => 2, min_d => 2, ar => 2) }    {carped => qr/Inserted unknown argument/}, 'method "cluster" rejects invented argument names';
warning_like { $white->cluster(radius => 1, minimal_distance => 1, 'ar') }    {carped => qr/Got odd number of values/}, 'all arguments have to be named';

@colors = $midblue->cluster( radius => 2.01, minimal_distance => 2, in => 'RGB' );
is( int @colors,                       13,    'computed smallest ball shaped cluster in RGB');
@values = $colors[0]->values();
is_tuple( \@values, [ 41, 52, 242], [qw/red green blue/], 'first color of cluster around mid blue');
@values = $colors[1]->values();
is_tuple( \@values, [   43, 52, 242], [qw/red green blue/], 'center color is on position two');
@values = $colors[2]->values();
is( $values[0],                        45,    'third color has more red');
@values = $colors[12]->values();
is_tuple( \@values, [   42, 51, 241], [qw/red green blue/], 'last color of cluster');

@colors = $midblue->cluster( r => [1.01,1.01,1.01], minimal_distance => 1, in => 'RGB');
is( int @colors,                       27,    'computed tiny cuboid cluster with 27 colors');
@values = $colors[0]->values();
is_tuple( \@values, [   42, 51, 241], [qw/red green blue/], 'first color of denser packed cluster');
@values = $colors[26]->values();
is_tuple( \@values, [   44, 53, 243], [qw/red green blue/], 'last color of denser packed cluster');

@colors = $white->cluster( r => [1.01,1.01,1.01], min_d => 1, in => 'HSL' );
is( int @colors,                       12,    'cluster edging on roof of HSL space');

exit 0;
