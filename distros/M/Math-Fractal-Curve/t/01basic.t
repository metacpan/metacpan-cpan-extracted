use strict;
use warnings;
use Test::More tests => 8;

use_ok('Math::Fractal::Curve');

my $c = Math::Fractal::Curve->new(generator=>[[0,0,1,0]]);
ok(1);

$c = $c->line(start => [0,0], end => [1,0]);
ok(1);

$c->edges();
ok(1);

$c->recurse();
ok(1);

$c->fractal(0);
ok(1);
$c->fractal(1);
ok(1);
$c->fractal(2);
ok(1);

