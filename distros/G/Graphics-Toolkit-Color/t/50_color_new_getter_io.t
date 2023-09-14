#!/usr/bin/perl
#
use v5.12;
use warnings;
use Test::More tests => 173;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color';
eval "use $module";
is( not( $@), 1, 'could load the module');

warning_like {Graphics::Toolkit::Color->new()}                    {carped => qr/constructor of/},       "need argument to create object";
warning_like {Graphics::Toolkit::Color->new('weirdcolorname')}    {carped => qr/unknown color/},        "accept only known color names";
warning_like {Graphics::Toolkit::Color->new('CHIMNEY:red')}       {carped => qr/ not installed/},       "accept only known palletes";
warning_like {Graphics::Toolkit::Color->new('#23232')       }     {carped => qr/could not recognize/},  "hex definition too short";
warning_like {Graphics::Toolkit::Color->new('#232321f')     }     {carped => qr/not recognize color/},  "hex definition too long";
warning_like {Graphics::Toolkit::Color->new('#23232g')       }    {carped => qr/not recognize color/},  "hex definition has forbidden chars";
warning_like {Graphics::Toolkit::Color->new('#2322%E')       }    {carped => qr/not recognize color/},  "hex definition has forbidden special chars";
warning_like {Graphics::Toolkit::Color->new(1,1)}                 {carped => qr/constructor of/},       "too few positional args";
warning_like {Graphics::Toolkit::Color->new(1,1,1,1,1)}           {carped => qr/constructor of/},       "too many positional args";
warning_like {Graphics::Toolkit::Color->new([1,1])}               {carped => qr/not recognize color/},  "too few positional args in ref";
warning_like {Graphics::Toolkit::Color->new([1,1,1,1])}           {carped => qr/not recognize color/},  "too many positional args in ref";
warning_like {Graphics::Toolkit::Color->new({ r=>1, g=>1})}       {carped => qr/not recognize color/},  "too few named args in ref";
warning_like {Graphics::Toolkit::Color->new({r=>1,g=>1,b=>1,h=>1,})} {carped => qr/not recognize color/},"too many name args in ref";
warning_like {Graphics::Toolkit::Color->new( r=>1)}               {carped => qr/constructor of/},       "too few named args";
warning_like {Graphics::Toolkit::Color->new(r=>1,g=>1,b=>1,h=>1,a=>1)} {carped => qr/constructor of/},  "too many name args";
warning_like {Graphics::Toolkit::Color->new(r=>1,g=>1,h=>1)}      {carped => qr/not recognize color/},   "don't mix named args";
warning_like {Graphics::Toolkit::Color->new(r=>1,g=>1,t=>1)}      {carped => qr/not recognize color/},   "don't invent named args";


my $red = Graphics::Toolkit::Color->new('red');
is( ref $red,        $module, 'could create object by name');
is( $red->red,           255, 'named red has correct red component value');
is( $red->green,           0, 'named red has correct green component value');
is( $red->blue,            0, 'named red has correct blue component value');
is( $red->hue,             0, 'named red has correct hue component value');
is( $red->saturation,    100, 'named red has correct saturation component value');
is( $red->lightness,      50, 'named red has correct lightness component value');
is( $red->name,        'red', 'named red has correct name');
is( $red->rgb_hex, '#ff0000', 'named red has correct hex value');
is(($red->rgb)[0],       255, 'named red has correct rgb red component value');
is(($red->rgb)[1],         0, 'named red has correct rgb green component value');
is(($red->rgb)[2],         0, 'named red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'named red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'named red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'named red has correct hsl lightness component value');
is(ref $red->rgb_hash,'HASH', 'named red has correct rgb HASH');
is(ref $red->hsl_hash,'HASH', 'named red has correct hsl HASH');
is( $red->rgb_hash->{'red'},  255, 'named red has correct red value in rgb HASH');
is( $red->rgb_hash->{'green'},  0, 'named red has correct green value in rgb HASH');
is( $red->rgb_hash->{'blue'},   0, 'named red has correct blue value in rgb HASH');
is( $red->hsl_hash->{'hue'},          0, 'named red has correct hue value in hsl HASH');
is( $red->hsl_hash->{'saturation'}, 100, 'named red has correct saturation value in hsl HASH');
is( $red->hsl_hash->{'lightness'},   50, 'named red has correct lightness value in hsl HASH');
is( $red->string,    'red', 'named red does stringify correctly');
is( Graphics::Toolkit::Color->new(15,12,13)->string, 'rgb: 15, 12, 13', 'random color does stringify correctly');


$red = Graphics::Toolkit::Color->new('#FF0000');
is( ref $red,        $module, 'could create object by hex value');
is( $red->red,           255, 'hex red has correct red component value');
is( $red->green,           0, 'hex red has correct green component value');
is( $red->blue,            0, 'hex red has correct blue component value');
is( $red->hue,             0, 'hex red has correct hue component value');
is( $red->saturation,    100, 'hex red has correct saturation component value');
is( $red->lightness,      50, 'hex red has correct lightness component value');
is( $red->name,        'red', 'hex red has correct name');
is( $red->rgb_hex, '#ff0000', 'hex red has correct hex value');
is(($red->rgb)[0],       255, 'hex red has correct rgb red component value');
is(($red->rgb)[1],         0, 'hex red has correct rgb green component value');
is(($red->rgb)[2],         0, 'hex red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'hex red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'hex red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'hex red has correct hsl lightness component value');

$red = Graphics::Toolkit::Color->new('#f00');
is( ref $red,     $module, 'could create object by short hex value');
is( $red->name,        'red', 'short hex red has correct name');

$red = Graphics::Toolkit::Color->new(255, 0, 0);
is( ref $red, $module, 'could create object by positional RGB');
is( $red->red,           255, 'positional red has correct red component value');
is( $red->green,           0, 'positional red has correct green component value');
is( $red->blue,            0, 'positional red has correct blue component value');
is( $red->hue,             0, 'positional red has correct hue component value');
is( $red->saturation,    100, 'positional red has correct saturation component value');
is( $red->lightness,      50, 'positional red has correct lightness component value');
is( $red->name,        'red', 'positional red has correct name');
is( $red->rgb_hex, '#ff0000', 'positional red has correct hex value');
is(($red->rgb)[0],       255, 'positional red has correct rgb red component value');
is(($red->rgb)[1],         0, 'positional red has correct rgb green component value');
is(($red->rgb)[2],         0, 'positional red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'positional red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'positional red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'positional red has correct hsl lightness component value');

$red = Graphics::Toolkit::Color->new([255, 0, 0]);
is( ref $red, $module, 'could create object by RGB array ref');
is( $red->red,           255, 'array ref red has correct red component value');
is( $red->green,           0, 'array ref red has correct green component value');
is( $red->blue,            0, 'array ref red has correct blue component value');
is( $red->hue,             0, 'array ref red has correct hue component value');
is( $red->saturation,    100, 'array ref red has correct saturation component value');
is( $red->lightness,      50, 'array ref red has correct lightness component value');
is( $red->name,        'red', 'array ref red has correct name');
is( $red->rgb_hex, '#ff0000', 'array ref red has correct hex value');
is(($red->rgb)[0],       255, 'array ref red has correct rgb red component value');
is(($red->rgb)[1],         0, 'array ref red has correct rgb green component value');
is(($red->rgb)[2],         0, 'array ref red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'array ref red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'array ref red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'array ref red has correct hsl lightness component value');

$red = Graphics::Toolkit::Color->new(r => 255, g => 0, b => 0);
is( ref $red, $module, 'could create object by RGB named args');
is( $red->red,           255, 'named arg red has correct red component value');
is( $red->green,           0, 'named arg red has correct green component value');
is( $red->blue,            0, 'named arg red has correct blue component value');
is( $red->hue,             0, 'named arg red has correct hue component value');
is( $red->saturation,    100, 'named arg red has correct saturation component value');
is( $red->lightness,      50, 'named arg red has correct lightness component value');
is( $red->name,        'red', 'named arg red has correct name');
is( $red->rgb_hex, '#ff0000', 'named arg red has correct hex value');
is(($red->rgb)[0],       255, 'named arg red has correct rgb red component value');
is(($red->rgb)[1],         0, 'named arg red has correct rgb green component value');
is(($red->rgb)[2],         0, 'named arg red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'named arg red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'named arg red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'named arg red has correct hsl lightness component value');

$red = Graphics::Toolkit::Color->new({Red => 255, Green => 0, Blue => 0 });
is( ref $red, $module, 'could create object by RGB hash ref');
is( $red->red,           255, 'hash ref red has correct red component value');
is( $red->green,           0, 'hash ref red has correct green component value');
is( $red->blue,            0, 'hash ref red has correct blue component value');
is( $red->hue,             0, 'hash ref red has correct hue component value');
is( $red->saturation,    100, 'hash ref red has correct saturation component value');
is( $red->lightness,      50, 'hash ref red has correct lightness component value');
is( $red->name,        'red', 'hash ref red has correct name');
is( $red->rgb_hex, '#ff0000', 'hash ref red has correct hex value');
is(($red->rgb)[0],       255, 'hash ref red has correct rgb red component value');
is(($red->rgb)[1],         0, 'hash ref red has correct rgb green component value');
is(($red->rgb)[2],         0, 'hash ref red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'hash ref red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'hash ref red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'hash ref red has correct hsl lightness component value');

$red = Graphics::Toolkit::Color->new({h => 0, s => 100, l => 50 });
is( ref $red, $module, 'could create object by HSL hash ref');
is( $red->red,           255, 'hash ref red has correct red component value');
is( $red->green,           0, 'hash ref red has correct green component value');
is( $red->blue,            0, 'hash ref red has correct blue component value');
is( $red->hue,             0, 'hash ref red has correct hue component value');
is( $red->saturation,    100, 'hash ref red has correct saturation component value');
is( $red->lightness,      50, 'hash ref red has correct lightness component value');
is( $red->name,        'red', 'hash ref red has correct name');
is( $red->rgb_hex, '#ff0000', 'hash ref red has correct hex value');
is(($red->rgb)[0],       255, 'hash ref red has correct rgb red component value');
is(($red->rgb)[1],         0, 'hash ref red has correct rgb green component value');
is(($red->rgb)[2],         0, 'hash ref red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'hash ref red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'hash ref red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'hash ref red has correct hsl lightness component value');

$red = Graphics::Toolkit::Color->new( Hue => 0, Saturation => 100, Lightness => 50 );
is( ref $red, $module, 'could create object by HSL named args');
is( $red->red,           255, 'hash ref red has correct red component value');
is( $red->green,           0, 'hash ref red has correct green component value');
is( $red->blue,            0, 'hash ref red has correct blue component value');
is( $red->hue,             0, 'hash ref red has correct hue component value');
is( $red->saturation,    100, 'hash ref red has correct saturation component value');
is( $red->lightness,      50, 'hash ref red has correct lightness component value');
is( $red->name,        'red', 'hash ref red has correct name');
is( $red->rgb_hex, '#ff0000', 'hash ref red has correct hex value');
is(($red->rgb)[0],       255, 'hash ref red has correct rgb red component value');
is(($red->rgb)[1],         0, 'hash ref red has correct rgb green component value');
is(($red->rgb)[2],         0, 'hash ref red has correct rgb blue component value');
is(($red->hsl)[0],         0, 'hash ref red has correct hsl hue component value');
is(($red->hsl)[1],       100, 'hash ref red has correct hsl saturation component value');
is(($red->hsl)[2],        50, 'hash ref red has correct hsl lightness component value');


my $c = Graphics::Toolkit::Color->new( 1,2,3 );
is( ref $red,     $module, 'could create object by random unnamed color');
is( $c->red,            1, 'random color has correct red component value');
is( $c->green,          2, 'random color has correct green component value');
is( $c->blue,           3, 'random color has correct blue component value');
is( $c->name,          '', 'random color has no name');
is( $c->string, 'rgb: 1, 2, 3', 'blue color was stringified to hex');

my $blue = Graphics::Toolkit::Color->new( 'blue' );
is( $blue->red,        0,  'blue has correct red component value');
is( $blue->green,      0,  'blue has correct green component value');
is( $blue->blue,     255,  'blue has correct blue component value');
is( $blue->hue,      240,  'blue has correct hue component value');
is( $blue->saturation,100, 'blue has correct saturation component value');
is( $blue->lightness,  50, 'blue has correct lightness component value');
is( $blue->name,   'blue', 'blue color has correct name');

my $recursive = Graphics::Toolkit::Color->new( $red );
is(  ref $recursive,                                  $module,   "recursive constructor option works");
ok(  $recursive != $red,                                         "recursive constructor produced object is new");
is(  $recursive->name,                                  'red',   "recursive constructor produced correct onject");


eval "color('blue')";
is( substr($@, 0, 20),  'Undefined subroutine', 'sub not there when not imported');

package New;

use Graphics::Toolkit::Color qw/color/;
use Test::More;

is (ref color('blue'), $module,                    'sub there when imported');
is (ref color('#ABC'), $module,                    'created color from short RGB hex string');
is (ref color('#AABBCC'), $module,                 'created color from long RGB hex string');
is (ref color([1,2,3]),   $module,                 'created color from Array Input');
is (ref color({r => 1, g => 2, b => 3,}), $module, 'created color from RGB hash');
is (ref color({h => 1, s => 2, l => 3,}), $module, 'created color from HSL hash');

exit 0;
