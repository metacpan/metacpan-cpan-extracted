use strict;
use Test::More tests => 13;

use Graphics::Primitive::Component;
use Graphics::Primitive::Container;

BEGIN {
    use_ok('Graphics::Primitive::ComponentList');
}

my $list = Graphics::Primitive::ComponentList->new;
isa_ok($list, 'Graphics::Primitive::ComponentList');

my $comp1 = Graphics::Primitive::Component->new(name => 'first', class => 'bar');
$list->add_component($comp1);
cmp_ok($list->component_count, '==', 1, 'component_count');

my $comp2 = Graphics::Primitive::Component->new(name => 'second', class => 'bar');
$list->add_component($comp2);
cmp_ok($list->component_count, '==', 2, 'component_count');

my $comp3 = Graphics::Primitive::Component->new(name => 'three', class => '2');
$list->add_component($comp3);

my $foundi = $list->find_component('first');
my $found = $list->get_component($foundi);
cmp_ok($found->name, 'eq', 'first', 'found first by name');

my $index1 = $list->get_component(0);
cmp_ok($index1->name, 'eq', 'first', 'found first by index');

my $index2 = $list->get_component(1);
cmp_ok($index2->name, 'eq', 'second', 'found second by index');

my $flist = $list->find(sub{ my ($comp, $const) = @_; return $comp->class eq 'bar' });
cmp_ok($flist->component_count, '==', 2, 'find list count');

$flist->each(sub { my ($comp, $const) = @_; $comp->name('foo'); });
cmp_ok($comp1->name, 'eq', 'foo', 'each changed component 1');
cmp_ok($comp2->name, 'eq', 'foo', 'each changed component 2');

$list->find(sub { my ($comp, $const) = @_; return $comp->name eq 'foo' })
    ->each(sub { my ($comp, $const) = @_; $comp->class('bar') });
cmp_ok($comp1->class, 'eq', 'bar', 'find->each changed component 1 class');
cmp_ok($comp2->class, 'eq', 'bar', 'find->each changed component 2 class');

my $cont1 = Graphics::Primitive::Container->new;
$cont1->add_component($comp1);
$cont1->add_component($comp2);
$cont1->add_component($comp3);

my $comp4 = Graphics::Primitive::Component->new(name => 'four', class => 'gorch');
my $comp5 = Graphics::Primitive::Component->new(name => 'five', class => 'baz');
my $cont2 = Graphics::Primitive::Container->new;
$cont2->add_component($comp4);
$cont2->add_component($comp5);

my $comp6 = Graphics::Primitive::Component->new(name => 'six', class => 'gorch');
my $cont3 = Graphics::Primitive::Container->new;
$cont3->add_component($comp6);

$cont1->add_component($cont2);
$cont1->add_component($cont3);

my $gorchlist = $cont1->find(sub {
    my ($comp, $const) = @_;
    return 0 unless defined($comp->class);
    return $comp->class eq 'gorch'
});
cmp_ok($gorchlist->component_count, '==', 2, 'sub-container find count');


