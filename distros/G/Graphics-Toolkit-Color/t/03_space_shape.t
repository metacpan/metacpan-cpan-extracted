#!/usr/bin/perl

use v5.12;
use warnings;
use Test::More tests => 75;
use Test::Warn;

BEGIN { unshift @INC, 'lib', '../lib'}
my $module = 'Graphics::Toolkit::Color::Space::Shape';
eval "use $module;";
is( not($@), 1, 'could load the module');

use Graphics::Toolkit::Color::Space::Basis;

my $obj = Graphics::Toolkit::Color::Space::Shape->new();
is( $obj,  undef,       'constructor needs arguments');

my $basis = Graphics::Toolkit::Color::Space::Basis->new( [qw/AAA BBB CCC/] );
is( Graphics::Toolkit::Color::Space::Shape->new( $basis, {}), undef, 'range definition needs to be an ARRAY');
is( Graphics::Toolkit::Color::Space::Shape->new( $basis, [[1,3],[1,3] ]), undef, 'not enough dimensions');
is( Graphics::Toolkit::Color::Space::Shape->new( $basis, [[1,3],[1,3],[1,3],[1,3] ]), undef, 'too many dimensions');
is( Graphics::Toolkit::Color::Space::Shape->new( $basis, [[1,3],[1,3],[1] ]), undef, 'one dimension had too short def');
is( Graphics::Toolkit::Color::Space::Shape->new( $basis, [[1,3],[1,3],[1,2,3] ]), undef, 'one dimension had too long def');
is( Graphics::Toolkit::Color::Space::Shape->new( $basis, [[1,3],[1,3],[2,2] ]), undef, 'range min is not smaller than max');
is( Graphics::Toolkit::Color::Space::Shape->new( $basis, [[1,3],[1,3],[1,2] ],{}), undef, 'type def has to be array too');
is( Graphics::Toolkit::Color::Space::Shape->new( $basis, [[1,3],[1,3],[1,2] ],[1,1]), undef, 'type def too short');
is( Graphics::Toolkit::Color::Space::Shape->new( $basis, [[1,3],[1,3],[1,2] ],[1,1,1,1]), undef, 'type def too long');
is( Graphics::Toolkit::Color::Space::Shape->new( $basis, [[1,3],[1,3],[1,2] ],[1,1,2]), undef, 'type def has out of range val');
is( Graphics::Toolkit::Color::Space::Shape->new( $basis, [[1,3],[1,3],[1,2] ],[1,1,'blub']), undef, 'unknown type name');

my $shape = Graphics::Toolkit::Color::Space::Shape->new( $basis, 20);
is( ref $shape,  $module, 'created shape with 0..20 range');
my $bshape = Graphics::Toolkit::Color::Space::Shape->new( $basis, [[-5,5],[-5,5],[-5,5]], ['angle', 'circular', 0]);
is( ref $bshape,  $module, 'created 3D bowl shape with -5..5 range');

my @d = $shape->delta(1, [1,5,4,5] );
is( int @d,   0, 'reject compute delta on none vector on first arg position');
@d = $shape->delta([1,5,4,5], 1 );
is( int @d,   0, 'reject compute delta on none vector on second arg position');
@d = $shape->delta([2,3,4,5], [1,5,4] );
is( int @d,   0, 'reject compute delta on too long first vector');
@d = $shape->delta([2,3], [1,5,1] );
is( int @d,   0, 'reject compute delta on too short first  vector');
@d = $shape->delta([2,3,4], [5,1,4,5] );
is( int @d,   0, 'reject compute delta on too long second vector');
@d = $shape->delta([2,3,4], [5,1] );
is( int @d,   0, 'reject compute delta on too short second  vector');

@d = $shape->delta([2,3,4], [1,5,1.1] );
is( int @d,   3, 'linear delta result has right length');
is( $d[0],   -1, 'first delta value correct');
is( $d[1],    2, 'second delta value correct');
is( $d[2],   -2.9, 'third delta value correct');

@d = $bshape->delta([0.1,0.9, .2], [0.9, 0.1, 0.8] );
is( int @d,   3, 'circular delta result has right length');
is( $d[0],   -0.2, 'first delta value correct');
is( $d[1],     .2, 'second delta value correct');
is( $d[2],   -0.4, 'third delta value correct');


my @tr = $shape->clamp([-1, 0, 20.1, 21, 1]);
is( int @tr,   3, 'clamp down to correct vector length = 3');
is( $tr[0],    0, 'clamp up value below minimum');
is( $tr[1],    0, 'do not touch minimal value');
is( $tr[2],   20, 'clamp real into int');

@tr = $shape->clamp( [360, 20] );
is( int @tr,   3, 'clamp added missing value');
is( $tr[0],   20, 'clamp down too large circular value');
is( $tr[1],   20, 'value was just max, clamped to min');
is( $tr[2],    0, 'added a zero into missing value');

@tr = $bshape->clamp( [-5.1, 6, 2] );
is( int @tr,   3, 'clamp kept right amount of values');
is( $tr[0],    5, 'rotated up too small value');
is( $tr[1],   -4, 'value was just max, clamped to min');
is( $tr[2],    2, 'in range valu is kept');

@tr = $shape->clamp( [6, -1, 11], [5,7,[-5, 10]] );
is( int @tr,   3, 'clamp with special range def');
is( $tr[0],    5, 'too larg value clamped down to max');
is( $tr[1],    0, 'too small value clamped up to min');
is( $tr[2],   10, 'clamped down into special range');


is( $shape->check([1,2,3]),   undef,  'all values in range');
warning_like {$shape->check([1,2])}       {carped => qr/value vector/},  "not enough values";
warning_like {$shape->check([1,2,3,4])}   {carped => qr/value vector/},  "too much values";
warning_like {$shape->check([-11,2,3])} {carped => qr/aaa value is below/},  "too small first value";
warning_like {$shape->check([0,21,3])}  {carped => qr/bbb value is above/},  "too large second value";
warning_like {$shape->check([0,1,3.1])} {carped => qr/be an integer/},        "third value was not int";


my @norm = $shape->normalize([0, 10, 20]);
is( int @norm,   3, 'normalized 3 into 3 values');
is( $norm[0],    0, 'normalized first min value');
is( $norm[1],    0.5, 'normalized second mid value');
is( $norm[2],    1,   'normalized third max value');

@norm = $shape->denormalize([0, 0.5 , 1]);
is( int @norm,   3, 'denormalized 3 into 3 values');
is( $norm[0],    0, 'denormalized min value');
is( $norm[1],   10, 'denormalized second mid value');
is( $norm[2],   20, 'denormalized third max value');

@norm = $bshape->normalize([-1, 0, 5]);
is( int @norm,   3, 'normalize bawl coordinates');
is( $norm[0],    0.4, 'normalized first min value');
is( $norm[1],    0.5, 'normalized second mid value');
is( $norm[2],    1,   'normalized third max value');

@norm = $bshape->denormalize([0.4, 0.5, 1]);
is( int @norm,   3, 'denormalized 3 into 3 values');
is( $norm[0],   -1, 'denormalized small value');
is( $norm[1],    0, 'denormalized mid value');
is( $norm[2],    5, 'denormalized max value');

@norm = $bshape->denormalize([1, 0, 0.5], [[-10,250],[30,50], [-70,70]]);
is( int @norm,   3, 'denormalized bowl with custom range');
is( $norm[0],  250, 'denormalized with special ranges max value');
is( $norm[1],   30, 'denormalized with special ranges min value');
is( $norm[2],    0, 'denormalized with special ranges mid value');

@norm = $bshape->normalize([250, 30, 0], [[-10,250],[30,50], [-70,70]]);
is( int @norm,  3,  'normalized  bowl with custom range');
is( $norm[0],   1,  'normalized with special ranges max value');
is( $norm[1],   0,  'normalized with special ranges min value');
is( $norm[2],   0.5,'normalized with special ranges mid value');

exit 0;
