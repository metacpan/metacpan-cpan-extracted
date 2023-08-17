#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 69;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Value';

eval "use $module";
is( not($@), 1, 'could load the module');

my $deformat      = \&Graphics::Toolkit::Color::Value::deformat;
my $format        = \&Graphics::Toolkit::Color::Value::format;
my $deconvert     = \&Graphics::Toolkit::Color::Value::deconvert;
my $convert       = \&Graphics::Toolkit::Color::Value::convert;
my $d             = \&Graphics::Toolkit::Color::Value::distance;


my @hsl = $convert->([127, 127, 127], 'HSL');
is( int @hsl,  3,     'converted hsl vector has right length');
is( $hsl[0],   0,     'converted color grey has computed right hue value');
is( $hsl[1],   0,     'converted color grey has computed right saturation');
is( $hsl[2],  50,     'converted color grey has computed right lightness');

my @rgb = $deconvert->([0, 0, 50], 'HSL');
is( int @rgb,  3,     'converted back color grey has rgb values');
is( $rgb[0], 127,     'converted back color grey has right red value');
is( $rgb[1], 127,     'converted back color grey has right green value');
is( $rgb[2], 127,     'converted back color grey has right blue value');


warning_like {$format->('112233', 'RGB', 'list')}      {carped => qr/array with right amount of values/},  "dont format none vectors";
warning_like {$format->([11,22,33,44], 'RGB', 'list')} {carped => qr/array with right amount of values/},  "dont format too long vectors";
warning_like {$format->([11,22], 'RGB', 'list')}       {carped => qr/array with right amount of values/},  "dont format too short vectors";

my $str = $format->([11,22,33], 'RGB', 'hex');
is( ref $str,           '',   'RGB string is not a reference');
is( uc $str,     '#0B1621',   'created a RGB hex string');

@rgb = $format->([11,22,33], 'RGB', 'list');
is( int @rgb,            3,   'RGB list has right length');
is( $rgb[0],            11,   'put red value first');
is( $rgb[1],            22,   'put green value second');
is( $rgb[2],            33,   'put red value third');

my $h = $format->([1,2,3],'HSL', 'hash');
is( ref $h,         'HASH',   'created a HSL hash');
is( $h->{'hue'},         1,   'put hue value under the right key');
is( $h->{'saturation'},  2,   'put saturation value under the right key');
is( $h->{'lightness'},   3,   'put lightness value under the right key');

$h = $format->([.2,.3,.4],'CMY', 'char_hash');
is( ref $h,         'HASH',   'created a CMY hash');
is( $h->{'c'},          .2,   'put hue value under the right key');
is( $h->{'m'},          .3,   'put saturation value under the right key');
is( $h->{'y'},          .4,   'put lightness value under the right key');

my ($rgb, $f) = $deformat->('#010203');
is( ref $rgb,      'ARRAY',   'deformated values int a list');
is( int @$rgb,           3,   'deformatted RGB hex string into triplet');
is( $rgb->[0],           1,   'deformatted red value from RGB hex string');
is( $rgb->[1],           2,   'deformatted green value from RGB hex string');
is( $rgb->[2],           3,   'deformatted blue value from RGB hex string');
is( $f,              'RGB',   'hex string was formatted in RGB');

($rgb, $f) = $deformat->('#FFF');
is( ref $rgb,      'ARRAY',   'deformated values int a list');
is( int @$rgb,           3,   'deformatted RGB short hex string into triplet');
is( $rgb->[0],         255,   'deformatted red value from short RGB hex string');
is( $rgb->[1],         255,   'deformatted green value from short RGB hex string');
is( $rgb->[2],         255,   'deformatted blue value from short RGB hex string');
is( $f,              'RGB',   'short hex string was formatted in RGB');

my($cmy, $for) = $deformat->({c => 0.1, m => 0.5, Y => 1});
is( ref $cmy,      'ARRAY',   'got cmy key hash deformatted');
is( int @$cmy,           3,   'deformatted CMY HASH into triplet');
is( $cmy->[0],         0.1,   'deformatted red value from CMY key HASH');
is( $cmy->[1],         0.5,   'deformatted green value from CMY key HASH');
is( $cmy->[2],           1,   'deformatted blue (not trimmed) value from CMY key HASH');
is( $for,            'CMY',   'key hash was formatted in CMY');

my($cmyk, $form) = $deformat->({c => -0.1, m => 0.5, Y => 2, k => 7});
is( ref $cmyk,     'ARRAY',   'got cmyk key hash deformatted');
is( int @$cmyk,          4,   'deformatted CMYK HASH into quadruel');
is( $cmyk->[0],       -0.1,   'deformatted red value from CMY key HASH');
is( $cmyk->[1],        0.5,   'deformatted green value from CMY key HASH');
is( $cmyk->[2],          2,   'deformatted blue (not trimmed) value from CMY key HASH');
is( $cmyk->[3],          7,   'deformatted blue (not trimmed) value from CMY key HASH');
is( $form,          'CMYK',   'key hash was formatted in CMY');


($rgb, $f) = $deformat->({c => 0.1, n => 0.5, Y => 1});
is( ref $rgb,           '',   'could not deformat cmy hash due bak key name');

warning_like { $d->([1, 2, 3,4], [  2, 6,11], 'RGB')}  {carped => qr/bad input values/},  "bad distance input: first vector";
warning_like { $d->([1, 2, 3],  [ 2, 6,11,4], 'RGB')}  {carped => qr/bad input values/},  "bad distance input: second vector";
warning_like { $d->([1, 2, 3],  [ 6,11,4], 'ABC')}     {carped => qr/unknown color space name/}, "bad distance input: space name";
warning_like { $d->([1, 2, 3],  [ 6,11,4], 'RGB','acd')} {carped => qr/that does not fit color space/}, "bad distance input: invalid subspace";


is( $d->([1, 2, 3], [  2, 6, 11], 'RGB'), 9,     'compute rgb distance');
is( $d->([1, 2, 3], [  2, 6, 11], 'HSL'), 9,     'compute hsl distance');
is( $d->([0, 2, 3], [359, 6, 11], 'HSL'), 9,     'compute hsl distance (test circular property of hsl)');

is( $d->([1, 1, 1], [  2, 3, 4], 'RGB', 'r'),  1, 'compute distance in red subspace');
is( $d->([1, 1, 1], [  2, 3, 4], 'RGB', 'R'),  1, 'subspace initials are case insensitive');
is( $d->([1, 1, 1], [  2, 3, 4], 'RGB', 'g'),  2, 'compute distance in green subspace');
is( $d->([1, 1, 1], [  2, 3, 4], 'RGB', 'b'),  3, 'compute distance in blue subspace');
is( $d->([1, 1, 1], [  4, 5, 6], 'RGB', 'rg'), 5, 'compute distance in rg subspace');
is( $d->([1, 1, 1], [  4, 5, 6], 'RGB', 'gr'), 5, 'compute distance in gr subspace');
is( $d->([1, 1, 1], [  4, 6, 5], 'RGB', 'rb'), 5, 'compute distance in rb subspace');
is( $d->([1, 1, 1], [ 12, 4, 5], 'RGB', 'gb'), 5, 'compute distance in gb subspace');
is( $d->([1, 2, 3], [  2, 6,11], 'RGB','rgb'), 9, 'distance in full subspace');
is( $d->([1, 2, 3], [  2, 6,11],            ), 9, 'default space is RGB');

exit 0;
