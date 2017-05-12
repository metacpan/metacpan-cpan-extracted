use Test::More tests => 16;

use Geometry::Primitive;

BEGIN {
    use_ok('Graphics::Primitive::Canvas');
    use_ok('Graphics::Primitive::Operation::Stroke');
}

my $canvas = Graphics::Primitive::Canvas->new;
isa_ok($canvas, 'Graphics::Primitive::Canvas');

my $point = Geometry::Primitive::Point->new(x => 0, y => 0);
ok($canvas->current_point->equal_to($point), 'starting point');

$canvas->move_to(5, 5);
$point->x(5); $point->y(5);
ok($canvas->current_point->equal_to($point), 'move_to');

$canvas->save;

$canvas->move_to(11, 5);
$point->x(11); $point->y(5);
ok($canvas->current_point->equal_to($point), 'move_to after save');

$canvas->restore;

$point->x(5); $point->y(5);
ok($canvas->current_point->equal_to($point), 'current after restore');

$point->x(12);
ok(!$canvas->current_point->equal_to($point), 'cloned');

$canvas->save;

cmp_ok($canvas->path->primitive_count, '==', 0, '0 primitives');

$canvas->do(Graphics::Primitive::Operation::Stroke->new);
$point->x(0); $point->y(0);
ok($canvas->current_point->equal_to($point), 'current after do');

$canvas->restore;

$point->x(5); $point->y(5);
ok($canvas->current_point->equal_to($point), 'current after restore');

$canvas->line_to(100, 100);
cmp_ok($canvas->path->primitive_count, '==', 1, '1 primitive');

$canvas->line_to(100, 100);
cmp_ok($canvas->get_path(0)->{path}->primitive_count, '==', 0, '0 primitives');

cmp_ok($canvas->path_count, '==', 1, '1 path');

$canvas->do(Graphics::Primitive::Operation::Stroke->new);

cmp_ok($canvas->path->primitive_count, '==', 0, 'fresh path');

cmp_ok($canvas->path_count, '==', 2, 'path count');

