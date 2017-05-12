use strict;
use Test::More tests => 11;

use Geometry::Primitive::Point;
use Graphics::Primitive::Component;
use Graphics::Primitive::Container;

use Layout::Manager::Flow;

my $foo = Graphics::Primitive::Component->new(
    name => 'one', minimum_height => 20, minimum_width => 30
);

my $foo2 = Graphics::Primitive::Component->new(
    name => 'two', minimum_height => 20, minimum_width => 30
);

my $cont = Graphics::Primitive::Container->new(width => 50);

$cont->add_component($foo);
$cont->add_component($foo2);

my $lm = Layout::Manager::Flow->new(anchor => 'east', wrap => 1);
$lm->do_layout($cont);

cmp_ok($foo->height, '==', 20, 'left bottom component height');
cmp_ok($foo->width, '==', 30, 'left component width');
cmp_ok($foo->origin->x, '==', 20, 'left component origin x');
cmp_ok($foo->origin->y, '==', 0, 'left component origin y');

cmp_ok($foo2->height, '==', 20, 'right component height');
cmp_ok($foo2->width, '==', 30, 'right component width');
cmp_ok($foo2->origin->x, '==', 20, 'right component origin x');
cmp_ok($foo2->origin->y, '==', 20, 'right component origin y');

cmp_ok($cont->minimum_height, '==', 40, 'minimum_height');

my $used = $lm->used;
cmp_ok($used->[0], '==', 30, 'width used');
cmp_ok($used->[1], '==', 40, 'height used');
