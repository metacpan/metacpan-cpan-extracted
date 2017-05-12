use Test::More tests => 29;

use Geometry::Primitive::Point;
use Graphics::Primitive::Component;
use Graphics::Primitive::Container;

BEGIN {
    use_ok('Layout::Manager::Axis');
}

my $foo = Graphics::Primitive::Component->new(
    name => 'one', minimum_height => 20, minimum_width => 20
);
my $foo2 = Graphics::Primitive::Component->new(
    name => 'two', minimum_height => 20, minimum_width => 20
);
my $foo3 = Graphics::Primitive::Component->new(
    name => 'three', minimum_height => 10, minimum_width => 20
);
my $foo4 = Graphics::Primitive::Component->new(
    name => 'four', minimum_height => 10, minimum_width => 30
);
my $foo5 = Graphics::Primitive::Component->new(
    name => 'five', minimum_height => 10, minimum_width => 10
);
my $foo6 = Graphics::Primitive::Component->new(
    name => 'six', minimum_height => 10, minimum_width => 10
);
my $foo7 = Graphics::Primitive::Component->new(
    name => 'seven', minimum_height => 10, minimum_width => 10
);

my $cont = Graphics::Primitive::Container->new(
    width => 400, height => 200,
    padding => Graphics::Primitive::Insets->new(
        top => 5, left => 4, right => 3, bottom => 2
    )
);

$cont->add_component($foo, 's');
$cont->add_component($foo2, 'w');
$cont->add_component($foo3, 'n');
$cont->add_component($foo4, 'e');
$cont->add_component($foo5, 'e');
$cont->add_component($foo6, 'c');
$cont->add_component($foo7, 'c');

my $lm = Layout::Manager::Axis->new;
$lm->do_layout($cont);

cmp_ok($foo->origin->x, '==', 24, 'bottom component origin x');
cmp_ok($foo->origin->y, '==', 178, 'bottom component origin y');
cmp_ok($foo->height, '==', 20, 'bottom component height');
cmp_ok($foo->width, '==', 333, 'bottom component width');

cmp_ok($foo2->origin->x, '==', 4, 'left component origin x');
cmp_ok($foo2->origin->y, '==', 15, 'left component origin y');
cmp_ok($foo2->height, '==', 163, 'left component height');
cmp_ok($foo2->width, '==', 20, 'left component width');

cmp_ok($foo3->origin->x, '==', 24, 'top component origin x');
cmp_ok($foo3->origin->y, '==', 5, 'top component origin y');
cmp_ok($foo3->height, '==', 10, 'top component height');
cmp_ok($foo3->width, '==', 333, 'top component width');

cmp_ok($foo4->origin->x, '==', 367, 'right component origin x');
cmp_ok($foo4->origin->y, '==', 15, 'right component origin y');
cmp_ok($foo4->height, '==', 163, 'right component height');
cmp_ok($foo4->width, '==', 30, 'right component width');

cmp_ok($foo5->origin->x, '==', 357, '2nd right component origin x');
cmp_ok($foo5->origin->y, '==', 15, '2nd right component origin y');
cmp_ok($foo5->height, '==', 163, '2nd right component height');
cmp_ok($foo5->width, '==', 10, '2nd right component width');

cmp_ok($foo6->origin->x, '==', 24, 'center component origin x');
cmp_ok($foo6->origin->y, '==', 15, 'center component origin y');
cmp_ok($foo6->height, '==', 81.5, 'center component height');
cmp_ok($foo6->width, '==', 333, 'center component width');

cmp_ok($foo7->origin->x, '==', 24, 'bottom center component origin x');
cmp_ok($foo7->origin->y, '==', 96.5, 'bottom center component origin y');
cmp_ok($foo7->height, '==', 81.5, 'bottom center component height');
cmp_ok($foo7->width, '==', 333, 'bottom center component width');
