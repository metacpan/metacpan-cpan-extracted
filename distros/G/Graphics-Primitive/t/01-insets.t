use Test::More tests => 15;

BEGIN {
    use_ok('Graphics::Primitive::Insets');
}

my $obj = Graphics::Primitive::Insets->new(
    top => 1,
    bottom => 2,
    left => 3,
    right => 4
);

cmp_ok($obj->top, '==', 1, 'top');
cmp_ok($obj->bottom, '==', 2, 'bottoms');
cmp_ok($obj->left, '==', 3, 'left');
cmp_ok($obj->right, '==', 4, 'right');

my $obj2 = Graphics::Primitive::Insets->new(
    top => 1,
    bottom => 2,
    left => 3,
    right => 5
);

ok($obj->not_equal_to($obj2), 'not equal');
$obj2->right(4);
ok($obj->equal_to($obj2), 'equal');

$obj->zero;
cmp_ok($obj->top, '==', 0, 'zero top');
cmp_ok($obj->left, '==', 0, 'zero left');
cmp_ok($obj->bottom, '==', 0, 'zero bottom');
cmp_ok($obj->right, '==', 0, 'zero right');

$obj->width(4);
cmp_ok($obj->top, '==', 4, 'width, top');
cmp_ok($obj->left, '==', 4, 'width, left');
cmp_ok($obj->bottom, '==', 4, 'width, bottom');
cmp_ok($obj->right, '==', 4, 'width, right');