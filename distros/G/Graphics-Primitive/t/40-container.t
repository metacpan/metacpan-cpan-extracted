use strict;
use Test::More tests => 12;

BEGIN {
    use_ok('Graphics::Primitive::Container');
}

use Graphics::Primitive::Component;

my $cont = Graphics::Primitive::Container->new(name => 'root');
isa_ok($cont, 'Graphics::Primitive::Container');

my $comp1 = Graphics::Primitive::Component->new(name => 'first');
$cont->add_component($comp1);
cmp_ok($cont->component_count, '==', 1, 'component_count');
cmp_ok($comp1->parent->name, 'eq', $cont->name, 'parent');

my $comp2 = Graphics::Primitive::Component->new(name => 'second');
$cont->add_component($comp2);
cmp_ok($cont->component_count, '==', 2, 'component_count');

my $foundi = $cont->find_component('first');
my $found = $cont->get_component($foundi);
cmp_ok($found->name, 'eq', 'first', 'found first by name');

my $index1 = $cont->get_component(0);
cmp_ok($index1->name, 'eq', 'first', 'found first by index');

my $index2 = $cont->get_component(1);
cmp_ok($index2->name, 'eq', 'second', 'found second by index');

$cont->prepared(1);
cmp_ok($cont->prepared, '==', 1, 'prepared');

my $comp3 = Graphics::Primitive::Component->new;

$cont->add_component($comp3);
cmp_ok($cont->prepared, '==', 0, 'not prepared');

my $removed = $cont->remove_component($comp2);
ok(!defined($comp2->parent), 'no parent after removal');

$cont->clear_components;
ok(!defined($comp1->parent), 'no parent after clear');