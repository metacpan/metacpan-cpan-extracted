use strict;
use Test::More tests => 11;

use Graphics::Primitive::Component;
use Graphics::Primitive::Container;

BEGIN {
    use_ok('Layout::Manager::Flow');
}

my $foo = Graphics::Primitive::Component->new(
    name => 'one', minimum_height => 20, minimum_width => 25
);

my $foo2 = Graphics::Primitive::Component->new(
    name => 'two', minimum_height => 20, minimum_width => 24
);

my $cont = Graphics::Primitive::Container->new(
    width => 100, height => 80
);

$cont->margins->left(10);
$cont->margins->top(11);
$cont->margins->right(12);
$cont->margins->bottom(9);

$cont->add_component($foo);
$cont->add_component($foo2);

my $lm = Layout::Manager::Flow->new(anchor => 'west');
$lm->do_layout($cont);

cmp_ok($foo->height, '==', 60, 'component 1 height');
cmp_ok($foo->width, '==', 25, 'component 1 width');
cmp_ok($foo->origin->x, '==', 10, 'component 1 origin x');
cmp_ok($foo->origin->y, '==', 11, 'component 1 origin y');

cmp_ok($foo2->height, '==', 60, 'component 2 height');
cmp_ok($foo2->width, '==', 24, 'component 2 width');
cmp_ok($foo2->origin->x, '==', 35, 'component 2 origin x');
cmp_ok($foo2->origin->y, '==', 11, 'component 2 origin y');

my $used = $lm->used;
cmp_ok($used->[0], '==', 49, 'width used');
cmp_ok($used->[1], '==', 60, 'height used');
