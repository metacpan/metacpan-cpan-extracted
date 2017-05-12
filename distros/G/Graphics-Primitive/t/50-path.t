use strict;
use Test::More tests => 14;

BEGIN {
    use_ok('Graphics::Primitive::Path');
    use_ok('Geometry::Primitive::Rectangle');
};

my $path = Graphics::Primitive::Path->new;
cmp_ok($path->primitive_count, '==', 0, 'primitive count');

my $start = Geometry::Primitive::Point->new(x => 0, y => 0);
$path->current_point($start);
ok($path->current_point->equal_to($start), 'current_point');

# Add A Line
my $line_end = Geometry::Primitive::Point->new(x => 10, y => 0);
$path->line_to($line_end);
ok($path->current_point->equal_to($line_end), 'line set current_point');
cmp_ok($path->primitive_count, '==', 1, 'primitive count');

# Move to, no primitives
my $mover = Geometry::Primitive::Point->new(x => 10, y => 10);
$path->move_to($mover);
ok($path->current_point->equal_to($mover), 'move_to set current_point');
cmp_ok($path->primitive_count, '==', 1, 'primitive count after move_to');

# Move to again, no primitive
$path->move_to(12, 12);
cmp_ok($path->current_point->x, '==', 12, 'move to with scalars');

$path->rel_move_to(5, 4);
my $chkpt = Geometry::Primitive::Point->new(x => 17, y => 16);
ok($path->current_point->equal_to($chkpt), 'rel_move_to');

$path->close_path;
my $line = $path->get_primitive($path->primitive_count - 1);
isa_ok($line, 'Geometry::Primitive::Line');
$chkpt->x(0); $chkpt->y(0);
ok($line->point_end->equal_to($chkpt), 'close path');

$path->arc(5, 0, 1.7);
my $a_line = $path->get_primitive($path->primitive_count - 2);
my $arc = $path->get_primitive($path->primitive_count - 1);

ok($path->current_point->equal_to($arc->point_end), 'post arc current_point');
isa_ok($line, 'Geometry::Primitive::Line');
