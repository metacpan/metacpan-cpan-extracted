use strict;
use Test::More tests => 17;

use Graphics::Primitive::Component;
use Graphics::Primitive::Container;

BEGIN {
    use_ok('Layout::Manager::Grid');
}

my $foo = Graphics::Primitive::Component->new(
    name => 'one', minimum_height => 20, minimum_width => 100
);
my $foo2 = Graphics::Primitive::Component->new(
    name => 'two', minimum_height => 20, minimum_width => 100
);
my $foo3 = Graphics::Primitive::Component->new(
    name => 'three', minimum_height => 20, minimum_width => 100
);
my $foo4 = Graphics::Primitive::Component->new(
    name => 'four', minimum_height => 20, minimum_width => 100
);

my $cont = Graphics::Primitive::Container->new(
    height => 200
);

$cont->add_component($foo, { row => 0, column => 0 });
$cont->add_component($foo2, { row => 0, column => 1 });
$cont->add_component($foo3, { row => 1, column => 0, height => 2 });
$cont->add_component($foo4, { row => 3, column => 0, width => 2 });

my $lm = Layout::Manager::Grid->new(rows => 4, columns => 2);
$lm->do_layout($cont);

cmp_ok($foo->height, '==', 55, 'left top component height');
cmp_ok($foo->width, '==', 100, 'left top component width');
cmp_ok($foo->origin->x, '==', 0, 'left top component origin x');
cmp_ok($foo->origin->y, '==', 0, 'left top component origin y');

cmp_ok($foo2->height, '==', 55, 'right top component height');
cmp_ok($foo2->width, '==', 100, 'right top component width');
cmp_ok($foo2->origin->x, '==', 100, 'right top component origin x');
cmp_ok($foo2->origin->y, '==', 0, 'right top component origin y');

cmp_ok($foo3->height, '==', 90, 'middle component height');
cmp_ok($foo3->width, '==', 100, 'middle component width');
cmp_ok($foo3->origin->x, '==', 0, 'middle component origin x');
cmp_ok($foo3->origin->y, '==', 55, 'middle component origin y');

cmp_ok($foo4->height, '==', 55, 'bottom component height');
cmp_ok($foo4->width, '==', 200, 'bottom component width');
cmp_ok($foo4->origin->x, '==', 0, 'bottom component origin x');
cmp_ok($foo4->origin->y, '==', 145, 'bottom component origin y');
