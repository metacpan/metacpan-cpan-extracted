use Test::More tests => 8;

BEGIN {
    use_ok('Graphics::Primitive::Brush');
}

my $obj = Graphics::Primitive::Brush->new(
    width => 3,
    line_cap => 'round',
    line_join => 'bevel'
);

cmp_ok($obj->width, '==', 3, 'width');
cmp_ok($obj->line_cap, 'eq', 'round', 'line_cap');
cmp_ok($obj->line_join, 'eq', 'bevel', 'line_join');

my $obj2 = $obj->clone;
ok($obj2->equal_to($obj), 'equal_to');

$obj->dash_pattern([ 1, 2, 3]);
$obj2->dash_pattern([ 1, 2, 3]);
ok($obj2->equal_to($obj), 'equal_to - dash_pattern');

my $obj3 = $obj->derive({ width => 4 });
ok($obj3->not_equal_to($obj), 'not_equal_to');

$obj2->dash_pattern([ 1, 2, 4]);
ok($obj2->not_equal_to($obj), 'not_equal_to - dash_pattern');