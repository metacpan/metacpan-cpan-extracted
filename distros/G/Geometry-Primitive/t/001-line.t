use Test::More tests => 16;

BEGIN {
    use_ok('Geometry::Primitive::Point');
    use_ok('Geometry::Primitive::Line');
};

my $point1 = Geometry::Primitive::Point->new(x => 1, y => 2);
my $point2 = Geometry::Primitive::Point->new(x => 3, y => 4);

my $line = Geometry::Primitive::Line->new(start => $point1, end => $point2);

ok($line->point_start->equal_to($point1), 'point_start');
ok($line->point_end->equal_to($point2), 'point_end');

cmp_ok($line->slope, '==', 1, 'slope');
cmp_ok($line->length, '==', sqrt(8), 'length');
cmp_ok($line->y_intercept, '==', 1, 'y_intercept');

ok($line->contains_point(-2, -1), 'contains_point');
ok(!$line->contains_point(-1, -1), 'contains_point (wrong)');

my $vert = Geometry::Primitive::Line->new(
    start => Geometry::Primitive::Point->new( x => 0, y => 0 ),
    end => Geometry::Primitive::Point->new( x => 0, y => 5 ),
);
ok(!defined($vert->slope), 'slope of vertical line');

my $horiz = Geometry::Primitive::Line->new(
    start => Geometry::Primitive::Point->new( x => 0, y => 0 ),
    end => Geometry::Primitive::Point->new( x => 5, y => 0 ),
);
cmp_ok($horiz->slope, '==', 0, 'slope of horizontal line');
ok($horiz->is_perpendicular($vert), 'vert/horiz perpendicular');
ok($vert->is_perpendicular($horiz), 'horiz/vert perpendicular');

my $line1 = Geometry::Primitive::Line->new(
    start => Geometry::Primitive::Point->new( x => 0, y => 1 ),
    end => Geometry::Primitive::Point->new( x => 1, y => 0 ),
);
my $line2 = Geometry::Primitive::Line->new(
    start => Geometry::Primitive::Point->new( x => 0, y => 0 ),
    end => Geometry::Primitive::Point->new( x => 1, y => 1 ),
);
ok($line1->is_perpendicular($line2), 'perpendicular');

my $cline = Geometry::Primitive::Line->new(start => [0, 0], end => [5, 5]);
cmp_ok($cline->start->x, '==', 0, 'point coercion');
ok($cline->slope, 'coerced line');

