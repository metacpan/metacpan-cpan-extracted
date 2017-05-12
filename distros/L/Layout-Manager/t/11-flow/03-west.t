use strict;
use Test::More tests => 10;

use Geometry::Primitive::Point;
use Graphics::Primitive::Component;
use Graphics::Primitive::Container;
use Layout::Manager::Flow;

my $foo = Graphics::Primitive::Component->new(
    name => 'one', minimum_height => 20, minimum_width => 30
);

my $foo2 = Graphics::Primitive::Component->new(
    name => 'two', minimum_height => 20, minimum_width => 15
);

my $cont = Graphics::Primitive::Container->new(
    width => 100, height => 40
);

$cont->add_component($foo);
$cont->add_component($foo2);

my $lm = Layout::Manager::Flow->new(anchor => 'west');
$lm->do_layout($cont);

cmp_ok($foo->height, '==', 40, 'left component height');
cmp_ok($foo->width, '==', 30, 'left component width');
cmp_ok($foo->origin->x, '==', 0, 'left component origin x');
cmp_ok($foo->origin->y, '==', 0, 'left component origin y');

cmp_ok($foo2->height, '==', 40, 'right component height');
cmp_ok($foo2->width, '==', 15, 'right component width');
cmp_ok($foo2->origin->x, '==', 30, 'right component origin x');
cmp_ok($foo2->origin->y, '==', 0, 'right component origin y');

my $used = $lm->used;
cmp_ok($used->[0], '==', 45, 'width used');
cmp_ok($used->[1], '==', 40, 'height used');
