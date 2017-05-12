use Test::More tests => 11;

use Geometry::Primitive::Point;
use Graphics::Primitive::Component;
use Graphics::Primitive::Container;

BEGIN {
    use_ok('Layout::Manager::Compass');
}

my $foo = Graphics::Primitive::Component->new(
    name => 'one', minimum_height => 20, minimum_width => 19
);

my $foo2 = Graphics::Primitive::Component->new(
    name => 'two', minimum_height => 10, minimum_width => 20
);

my $cont = Graphics::Primitive::Container->new(
    width => 100, height => 40
);

$cont->add_component($foo, 'w');
cmp_ok($cont->component_count, '==', 1, 'component_count');

$cont->add_component($foo2, 'e');
cmp_ok($cont->component_count, '==', 2, 'component_count');

my $lm = Layout::Manager::Compass->new;
$lm->do_layout($cont);

cmp_ok($foo->width, '==', 19, 'left component width');
cmp_ok($foo->height, '==', 40, 'left component height');
cmp_ok($foo->origin->x, '==', 0, 'left component origin x');
cmp_ok($foo->origin->y, '==', 0, 'left component origin y');

cmp_ok($foo2->width, '==', 20, 'right component width');
cmp_ok($foo2->height, '==', 40, 'right component height');
cmp_ok($foo2->origin->x, '==', 80, 'right component origin x');
cmp_ok($foo2->origin->y, '==', 0, 'right component origin y');
