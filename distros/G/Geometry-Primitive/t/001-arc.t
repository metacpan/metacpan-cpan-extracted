use Test::More tests => 8;

use Geometry::Primitive::Point;

BEGIN {
    use_ok('Geometry::Primitive::Arc');
};

my $arc = Geometry::Primitive::Arc->new(
    origin => Geometry::Primitive::Point->new(x => 0, y => 0),
    angle_start => 0, angle_end => 1.57079633, radius => 5
);

cmp_ok($arc->angle_start, '==', 0, 'angle start');
cmp_ok($arc->angle_end, '==', 1.57079633, 'angle end');
cmp_ok($arc->radius, '==', 5, 'radius');
ok($arc->length =~ /^7.8/, 'length');
ok(defined($arc->get_point_at_angle(1.5)), 'get_point_at_angle bounds check');
ok(defined($arc->point_start), 'point_start');
ok(defined($arc->point_end), 'point_end');