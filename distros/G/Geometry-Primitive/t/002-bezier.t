use Test::More tests => 6;

BEGIN {
    use_ok('Geometry::Primitive::Point');
    use_ok('Geometry::Primitive::Bezier');
};

my $point1 = Geometry::Primitive::Point->new(x => 0, y => 0);
my $point2 = Geometry::Primitive::Point->new(x => 0, y => 10);

my $c1 = Geometry::Primitive::Point->new(x => 5, y => 5);
my $c2 = Geometry::Primitive::Point->new(x => 7, y => 6);

my $bezier = Geometry::Primitive::Bezier->new(
    start => $point1,
    end => $point2,
    control1 => [5, 5],
    control2 => $c2
);
isa_ok($bezier, 'Geometry::Primitive::Bezier');

ok($bezier->point_start->equal_to($point1), 'point_start');
ok($bezier->point_end->equal_to($point2), 'point_end');
ok($bezier->control1->equal_to($c1), 'coerced control point');