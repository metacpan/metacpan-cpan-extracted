use Test::More tests => 19;

BEGIN {
    use_ok('Graphics::Primitive::Component');
}

use Graphics::Color::RGB;
use Geometry::Primitive::Point;
use Graphics::Primitive::Border;
use Graphics::Primitive::Insets;

my $color = Graphics::Color::RGB->new();
my $color2 = Graphics::Color::RGB->new(red => .58);
my $border = Graphics::Primitive::Border->new;
$border->width(2);
my $margins = Graphics::Primitive::Insets->new( top => 5, left => 6, bottom => 7, right => 8 );
my $padding = Graphics::Primitive::Insets->new( top => 1, left => 2, bottom => 3, right => 4 );
my $point = Geometry::Primitive::Point->new( x => 5, y => 6 );

my $obj = Graphics::Primitive::Component->new(
    background_color    => $color,
    border              => $border,
    color               => $color2,
    origin              => $point,
    margins             => $margins,
    padding             => $padding,
    width               => 100,
    height              => 200
);

cmp_ok($obj->background_color->red, '==', $color->red, 'background color');
cmp_ok($obj->color->red, '==', $color2->red, 'color');
cmp_ok($obj->border->left->width, '==', 2, 'border');
ok($obj->origin->equal_to($point), 'origin');
ok($obj->margins->equal_to($margins), 'margins');
ok($obj->padding->equal_to($padding), 'padding');
cmp_ok($obj->width, '==', 100, 'width');
cmp_ok($obj->height, '==', 200, 'height');
cmp_ok($obj->visible, '==', 1, 'visible');

cmp_ok($obj->inside_width, '==', 76, 'inside_width');
cmp_ok($obj->inside_height, '==', 180, 'inside_height');

my $ulip = Geometry::Primitive::Point->new(x => 10, y => 8);
my $bb = $obj->inside_bounding_box;
ok($bb->origin->equal_to($ulip), 'bounding box');

$obj->prepared(1);
cmp_ok($obj->prepared, '==', 1, 'prepared');
$obj->width(101);
cmp_ok($obj->prepared, '==', 0, 'not prepared');

$obj->width(100);
$obj->border->left->width(3);
cmp_ok($obj->inside_width, '==', 75, 'left border width');
$obj->border->right->width(3);
cmp_ok($obj->inside_width, '==', 74, 'right border width');

$obj->height(200);
$obj->border->top->width(3);
cmp_ok($obj->inside_height, '==', 179, 'top border width');
$obj->border->bottom->width(3);
cmp_ok($obj->inside_height, '==', 178, 'bottom border width');

