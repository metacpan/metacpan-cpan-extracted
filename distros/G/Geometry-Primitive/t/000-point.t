use Test::More tests => 5;

BEGIN {
    use_ok('Geometry::Primitive::Point');
};

my $point = Geometry::Primitive::Point->new();
$point->x(1);
$point->y(2);
cmp_ok($point->x, '==', 1, 'x value');
cmp_ok($point->y, '==', 2, 'y value');

my $point2 = Geometry::Primitive::Point->new(x => 1, y => 2);
ok($point->equal_to($point2), 'point equality');
$point2->x(0);
ok(!$point->equal_to($point2), 'point inequality');