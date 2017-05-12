use Test::More tests => 43;

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

my $legend2 = Graphics::Primitive::Container->new(
    layout_manager => Layout::Manager::Compass->new, name => 'legend2'
);
my $text3 = Graphics::Primitive::Component->new( minimum_width => 10, minimum_height => 15);
my $text4 = Graphics::Primitive::Component->new( minimum_width => 10, minimum_height => 10);
$legend2->add_component($text3, 'n');
$legend2->add_component($text4, 'w');

my $legend3 = Graphics::Primitive::Container->new(
    layout_manager => Layout::Manager::Compass->new, name => 'legend3'
);
my $text5 = Graphics::Primitive::Component->new( minimum_width => 10, minimum_height => 15);
my $text6 = Graphics::Primitive::Component->new( minimum_width => 15, minimum_height => 10);
my $text7 = Graphics::Primitive::Component->new( minimum_width => 10, minimum_height => 5);
$legend3->add_component($text5, 'c');
$legend3->add_component($text6, 'e');
$legend3->add_component($text7, 'n');

my $cont = new Graphics::Primitive::Container(
    width => 120, height => 100,
    padding => Graphics::Primitive::Insets->new(
        top => 5, left => 4, right => 3, bottom => 2
    )
);

$cont->add_component($legend, 's');
$cont->add_component($legend2, 'n');
$cont->add_component($legend3, 'w');

cmp_ok($cont->component_count, '==', 3, 'root component_count');
cmp_ok($legend->component_count, '==', 2, 'legend component_count');
cmp_ok($legend2->component_count, '==', 2, 'legend2 component_count');
cmp_ok($legend3->component_count, '==', 3, 'legend3 component_count');

my $lm = Layout::Manager::Compass->new;
$cont->layout_manager($lm);
$cont->do_layout($cont);

cmp_ok($legend->origin->x, '==', 4, 'legend origin x');
cmp_ok($legend->origin->y, '==', 83, 'legend origin y');
cmp_ok($legend->width, '==', 113, 'legend width');
cmp_ok($legend->height, '==', 15, 'legend height');

# cmp_ok($text1->origin->x, '==', 107, 'text1 origin x');
cmp_ok($text1->origin->y, '==', 0, 'text1 origin y');
cmp_ok($text1->width, '==', 10, 'text1 width');
cmp_ok($text1->height, '==', 15, 'text1 height');

cmp_ok($text2->origin->x, '==', 0, 'text2 origin x');
cmp_ok($text2->origin->y, '==', 0, 'text2 origin y');
cmp_ok($text2->width, '==', 15, 'text2 width');
cmp_ok($text2->height, '==', 15, 'text2 height');

cmp_ok($legend2->origin->x, '==', 4, 'legend2 origin x');
cmp_ok($legend2->origin->y, '==', 5, 'legend2 origin y');
cmp_ok($legend2->width, '==', 113, 'legend2 width');
cmp_ok($legend2->height, '==', 25, 'legend2 height');

cmp_ok($text3->origin->x, '==', 0, 'text3 origin x');
cmp_ok($text3->origin->y, '==', 0, 'text3 origin y');
cmp_ok($text3->width, '==', 113, 'text3 width');
cmp_ok($text3->height, '==', 15, 'text3 height');

cmp_ok($text4->origin->x, '==', 0, 'text4 origin x');
cmp_ok($text4->origin->y, '==', 15, 'text4 origin y');
cmp_ok($text4->width, '==', 10, 'text4 width');
cmp_ok($text4->height, '==', 10, 'text4 height');

cmp_ok($legend3->origin->x, '==', 4, 'legend 3 origin x');
cmp_ok($legend3->origin->y, '==', 30, 'legend 3 origin y');
cmp_ok($legend3->width, '==', 25, 'legend 3 width');
# cmp_ok($legend3->height, '==', 25, 'legend 3 height');

cmp_ok($text5->origin->x, '==', 0, 'text5 origin x');
cmp_ok($text5->origin->y, '==', 5, 'text5 origin y');
cmp_ok($text5->width, '==', 10, 'text5 width');
cmp_ok($text5->height, '==', 48, 'text5 height');

cmp_ok($text6->origin->x, '==', 10, 'text6 origin x');
cmp_ok($text6->origin->y, '==', 5, 'text6 origin y');
cmp_ok($text6->width, '==', 15, 'text6 width');
cmp_ok($text6->height, '==', 48, 'text6 height');

cmp_ok($text7->origin->x, '==', 0, 'text7 origin x');
cmp_ok($text7->origin->y, '==', 0, 'text7 origin y');
cmp_ok($text7->width, '==', 25, 'text7 width');
cmp_ok($text7->height, '==', 5, 'text7 height');