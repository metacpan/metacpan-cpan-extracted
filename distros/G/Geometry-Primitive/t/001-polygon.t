use Test::More tests => 9;

BEGIN {
    use_ok('Geometry::Primitive::Point');
    use_ok('Geometry::Primitive::Polygon');
};

my $poly = Geometry::Primitive::Polygon->new;
my $point1 = Geometry::Primitive::Point->new(x => 0, y => 0);
$poly->add_point($point1);
my $point2 = Geometry::Primitive::Point->new(x => 0, y => 1);
$poly->add_point($point2);
my $point3 = Geometry::Primitive::Point->new(x => 1, y => 1);
$poly->add_point($point3);
my $point4 = Geometry::Primitive::Point->new(x => 1, y => 0);
$poly->add_point($point4);
my $point5 = Geometry::Primitive::Point->new(x => 0, y => 0);
$poly->add_point($point5);

cmp_ok($poly->point_count, '==', 5, 'point count');
ok($poly->get_point(0)->equal_to($point1), 'get point 1');
ok($poly->point_start->equal_to($point1), 'start point');
ok($poly->point_end->equal_to($point1), 'end point');

cmp_ok($poly->area, '==', 1, 'area');

$poly->scale(2);

cmp_ok($poly->area, '==', 4, 'scaled area');

$poly->clear_points;
cmp_ok($poly->point_count, '==', 0, 'cleared points');
