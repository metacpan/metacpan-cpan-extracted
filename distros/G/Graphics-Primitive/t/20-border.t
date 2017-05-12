use Test::More;

BEGIN {
    use_ok('Graphics::Primitive::Border');
}

use Graphics::Color::RGB;

my $color = Graphics::Color::RGB->new(red => .3);

my $obj = Graphics::Primitive::Border->new;

$obj->color($color);
$obj->width(3);

cmp_ok($obj->left->color->red, '==', $color->red, 'left color');
cmp_ok($obj->right->color->red, '==', $color->red, 'right color');
cmp_ok($obj->top->color->red, '==', $color->red, 'top color');
cmp_ok($obj->bottom->color->red, '==', $color->red, 'bottom color');

cmp_ok($obj->left->width, '==', 3, 'left width');
cmp_ok($obj->right->width, '==', 3, 'right width');
cmp_ok($obj->top->width, '==', 3, 'top width');
cmp_ok($obj->bottom->width, '==', 3, 'bottom width');

my $other = $obj->clone;
ok($obj->equal_to($other), 'equal_to');
my $color2 = Graphics::Color::RGB->new(red => 1, green => .3);
$other->left->color($color2);
ok($obj->not_equal_to($other), 'not_equal_to');

ok(!$other->homogeneous, 'not homogeneous');

$other->width(3);
$other->color($color);
ok($other->homogeneous, 'homogenous');

my $b2 = Graphics::Primitive::Border->new( color => $color, width => 5 );
cmp_ok($b2->top->width, '==', 5, 'width in constructor');
cmp_ok($b2->top->color->red, '==', .3, 'color in constructor');

done_testing;