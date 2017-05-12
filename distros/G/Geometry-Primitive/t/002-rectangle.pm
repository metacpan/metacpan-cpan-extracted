use Test::More tests => 11;

BEGIN {
    use_ok('Geometry::Primitive::Point');
    use_ok('Geometry::Primitive::Rectangle');
};

my $orig = Geometry::Primitive::Point->new(x => 0, y => 0);
my $rect = Geometry::Primitive::Rectangle->new(
    origin => $orig,
    width => 5,
    height => 10
);

cmp_ok($rect->area(), '==', 50, 'area');
my $points = $rect->get_points();
cmp_ok(scalar(@{ $points }), '==', 4, 'correct number of points');
ok($points->[0]->equal_to($orig), 'first point');
cmp_ok($points->[1]->x, '==', 5, 'second point x');
cmp_ok($points->[1]->y, '==', 0, 'second point y');

cmp_ok($points->[2]->x, '==', 0, 'third point x');
cmp_ok($points->[2]->y, '==', 10, 'third point y');

cmp_ok($points->[3]->x, '==', 5, 'third point x');
cmp_ok($points->[3]->y, '==', 10, 'third point y');