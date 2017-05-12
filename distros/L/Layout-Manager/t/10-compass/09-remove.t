use Test::More tests => 19;

use Geometry::Primitive::Point;
use Graphics::Primitive::Component;
use Graphics::Primitive::Container;

BEGIN {
    use_ok('Layout::Manager::Compass');
}

my $north = Graphics::Primitive::Component->new(
    minimum_height => 10, minimum_width => 10, name => 'north'
);
my $south = Graphics::Primitive::Component->new(
    minimum_height => 10, minimum_width => 10
);
my $east = Graphics::Primitive::Component->new(
    minimum_height => 10, minimum_width => 10
);
my $west = Graphics::Primitive::Component->new(
    minimum_height => 10, minimum_width => 10
);
my $center = Graphics::Primitive::Component->new(
    minimum_height => 10, minimum_width => 10
);

my $cont = Graphics::Primitive::Container->new(
    width => 120, height => 100
);

$cont->add_component($north, 'n');
$cont->add_component($south, 's');
$cont->add_component($east, 'e');
$cont->add_component($west, 'w');
$cont->add_component($center, 'c');

my $count = $cont->remove_component('north');
cmp_ok(scalar(@{ $count }), '==', 1, 'removed north');

cmp_ok($cont->component_count, '==', 5, 'component_count');

my $lm = Layout::Manager::Compass->new();
$lm->do_layout($cont);

cmp_ok($south->origin->x, '==', 0, 'south origin x');
cmp_ok($south->origin->y, '==', 90, 'south origin y');
cmp_ok($south->width, '==', 120, 'south width');
cmp_ok($south->height, '==', 10, 'south height');

cmp_ok($east->origin->x, '==', 110, 'east origin x');
cmp_ok($east->origin->y, '==', 0, 'east origin y');
cmp_ok($east->width, '==', 10, 'east width');
cmp_ok($east->height, '==', 90, 'east height');

cmp_ok($west->origin->x, '==', 0, 'west origin x');
cmp_ok($west->origin->y, '==', 0, 'west origin y');
cmp_ok($west->width, '==', 10, 'west width');
cmp_ok($west->height, '==', 90, 'west height');

cmp_ok($center->origin->x, '==', 10, 'center origin x');
cmp_ok($center->origin->y, '==', 0, 'center origin y');
cmp_ok($center->width, '==', 100, 'center width');
cmp_ok($center->height, '==', 90, 'center height');