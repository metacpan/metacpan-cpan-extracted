#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 40;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Values';

eval "use $module";
is( not($@), 1, 'could load the module');
use Graphics::Toolkit::Color::Space::Util ':all';

sub val {Graphics::Toolkit::Color::Values->new( $_[0] )}

my $v = val('#010203');
is( ref $v,        $module,    'could create an object from rgb hex');
is( close_enough($v->{'RGB'}[0],  1/255), 1,  'normalized red value correct');
is( close_enough($v->{'RGB'}[1],  2/255), 1,  'normalized green value correct');
is( close_enough($v->{'RGB'}[2],  3/255), 1,  'normalized blue value correct');

my @values = $v->get;
is( int @values,           3,    'rgb values are three');
is( $values[0],            1,    'spat out original red');
is( $values[1],            2,    'spat out original green');
is( $values[2],            3,    'spat out original blue');

$v = Graphics::Toolkit::Color::Values->new('hsl(240,100,50)');
is( ref $v,        $module,    'could create an object from hsl css_string');
is( $v->{'RGB'}[0],  0,  'normalized red value');
is( $v->{'RGB'}[1],  0,  'normalized green value');
is( $v->{'RGB'}[2],  1,  'normalized blue value');
is( close_enough($v->{'HSL'}[0],  2/3), 1, 'normalized hue value');
is( close_enough($v->{'HSL'}[1],  1),   1, 'normalized saturation value');
is( close_enough($v->{'HSL'}[2],  0.5), 1, 'normalized lightness value');

is( $v->get('hsl','string'), 'hsl: 240, 100, 50', 'got all original values back in string format');
is( $v->string(),            'hsl: 240, 100, 50', 'string method works');
is( uc $v->get('RGB','HEX'), '#0000FF', 'got values in RGB hex format');

my $violet = $v->set({red => 255});
is( ref $violet,     $module,             'created related color by set method');
is( uc $violet->get('RGB','HEX'), '#FF00FF', 'red value got boosted');

my $black = $violet->set({blackness => 100});
is( $black->get('RGB','HEX'), '#000000', 'made color black');


my $vn = $v->add({green => -10}) ;
is( ref $violet,     $module,             'added negative green value');
is( uc $vn->get('RGB','HEX'), '#0000FF', 'color got clamped into defined RGB');

$vn = $v->add({green => 10});
is( uc $vn->get('RGB','HEX'), '#000AFF', 'could add green');

my $vb = $v->blend( $vn, undef, 'RGB' );
is( ref $vb,      $module,    'could blend two colors');
is( $vb->{'RGB'}[0], 0, 'red value correct');
is( close_enough($vb->{'RGB'}[1], 5/255), 1, 'blue value correct');
is( $vb->{'RGB'}[2], 1, 'blue value correct');

is( uc $v->blend( $vn, 0 )->get('RGB','HEX'), '#0000FF', 'blended nothing, kept original');
is( uc $v->blend( $violet, 1 )->get('RGB','HEX'), '#FF00FF', 'blended nothing, kept paint color');
is( uc $v->blend( $violet, 3, 'RGB' )->get('RGB','HEX'), '#FF00FF', 'clamp kept color in range');


my $one = val( [1,2,3] );
my $blue = val( '#0000FF' );
my $yellow = val( '#FFFF00' );
warning_like { $one->distance()}               {carped => qr/need value object/},  "need at least second color";
warning_like { $one->distance([RGB =>1,2,3])}  {carped => qr/need value object/},  "need value object, not a definition";
is( close_enough( $one->distance( val( [ 2, 3, 4] ), 'RGB', undef, 255), sqrt(3)), 1,   'computed simple rgb distance');
is(               $one->distance( val( [ 2, 3, 4] ), 'RGB', 'b', 255),             1,   'only blue metric');
is( close_enough( $one->distance( val( [ 2, 3, 4] ), 'RGB', 'rrgb', 255), 2),      1,   'double red metric');
is( close_enough( $blue->distance( $yellow, undef, 'h', 'normal'), 0.5),           1,   'complement color has maximal hue distance, 0.5 normalized');
is(               $blue->distance( $yellow, undef, 'h'),                         180,   'complement has maximal hue distance');
is(               $blue->distance( $yellow, undef, 'h', [[-100,100],1,1,]),      100,   'maximal hue distance with special range');

exit 0;
