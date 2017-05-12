use strict;
use Test::More tests => 12;

use Graphics::Primitive::Component;
use Graphics::Primitive::Container;

BEGIN {
    use_ok('Layout::Manager::Flow');
}

my $foo = Graphics::Primitive::Component->new(
    name => 'one', minimum_height => 20, minimum_width => 100
);

my $foo2 = Graphics::Primitive::Component->new(
    name => 'two', minimum_height => 20, minimum_width => 100
);

my $cont = Graphics::Primitive::Container->new(
    height => 80
);

$cont->add_component($foo);
$cont->add_component($foo2);

my $lm = Layout::Manager::Flow->new(anchor => 'north');
$lm->do_layout($cont);

cmp_ok($foo->height, '==', 20, 'top component height');
cmp_ok($foo->width, '==', 100, 'top component width');
cmp_ok($foo->origin->x, '==', 0, 'top component origin x');
cmp_ok($foo->origin->y, '==', 0, 'top component origin y');

cmp_ok($foo2->height, '==', 20, 'bottom component height');
cmp_ok($foo2->width, '==', 100, 'bottom component width');
cmp_ok($foo2->origin->x, '==', 0, 'bottom component origin x');
cmp_ok($foo2->origin->y, '==', 20, 'bottom component origin y');

cmp_ok($cont->minimum_width, '==', 100, 'container width');

my $used = $lm->used;
cmp_ok($used->[0], '==', 100, 'width used');
cmp_ok($used->[1], '==', 40, 'height used');
