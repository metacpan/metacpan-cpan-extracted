use Test::More;
use strict;

BEGIN {
    use_ok('Geometry::Primitive::Dimension');
};

my $dim = Geometry::Primitive::Dimension->new(width => 1, height => 2);
cmp_ok($dim->width, '==', 1, 'width value');
cmp_ok($dim->height, '==', 2, 'height value');

my $dim2 = Geometry::Primitive::Dimension->new(width => 1, height => 2);
ok($dim->equal_to($dim2), 'dimension equality');
$dim2->width(0);
ok(!$dim->equal_to($dim2), 'dimension inequality');

done_testing;