use Test::More tests => 15;

use Graphics::Primitive::Insets;
use Geometry::Primitive::Point;
use Layout::Manager::Compass;
use Graphics::Primitive::Container;
use Graphics::Primitive::Component;

BEGIN {
    use_ok('Layout::Manager::Compass');
}

my $legend = Graphics::Primitive::Container->new(
    layout_manager => Layout::Manager::Compass->new, name => 'legend'
);
my $text1 = Graphics::Primitive::Component->new( minimum_width => 10, minimum_height => 15);
my $text2 = Graphics::Primitive::Component->new( minimum_width => 15, minimum_height => 10);
$legend->add_component($text1, 'e');
$legend->add_component($text2, 'w');


my $cont = new Graphics::Primitive::Container(
    width => 120, height => 100,
    padding => Graphics::Primitive::Insets->new(
        top => 5, left => 4, right => 3, bottom => 2
    )
);

my $text3 = Graphics::Primitive::Component->new( minimum_width => 13, minimum_height => 11);

$cont->add_component($text3, 's');
$cont->add_component($legend, 'c');

cmp_ok($cont->component_count, '==', 2, 'root component_count');
cmp_ok($legend->component_count, '==', 2, 'legend component_count');

my $lm = Layout::Manager::Compass->new;
$cont->layout_manager($lm);
$cont->do_layout($cont);

cmp_ok($legend->origin->x, '==', 4, 'legend origin x');
cmp_ok($legend->origin->y, '==', 5, 'legend origin y');
cmp_ok($legend->width, '==', 113, 'legend width');
cmp_ok($legend->height, '==', 82, 'legend height');

cmp_ok($text1->origin->x, '==', 103, 'text1 origin x');
cmp_ok($text1->origin->y, '==', 0, 'text1 origin y');
cmp_ok($text1->width, '==', 10, 'text1 width');
cmp_ok($text1->height, '==', 82, 'text1 height');

cmp_ok($text2->origin->x, '==', 0, 'text2 origin x');
cmp_ok($text2->origin->y, '==', 0, 'text2 origin y');
cmp_ok($text2->width, '==', 15, 'text2 width');
cmp_ok($text2->height, '==', 82, 'text2 height');
