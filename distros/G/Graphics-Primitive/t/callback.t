use lib 't/lib', 'lib';
use strict;

use Test::More;

use Graphics::Primitive::Component;
use Graphics::Primitive::Container;

BEGIN {
    use_ok('Graphics::Primitive::Driver');
    use_ok('DummyDriver');
}

my $driver = DummyDriver->new;
isa_ok($driver, 'DummyDriver');

my $container = Graphics::Primitive::Container->new(class => 'container');
my $comp = Graphics::Primitive::Component->new(class => 'component');
my $comp_call = 0;
$comp->callback(sub { $comp_call = $_[0]->class });

$container->add_component($comp, 'c');

my $cont_call = 0;
use Data::Dumper;
$container->callback(sub { $cont_call = $_[0]->class });

$driver->prepare($container);
$driver->finalize($container);

cmp_ok($cont_call, 'eq', 'container', 'container callback fired');
cmp_ok($comp_call, 'eq', 'component', 'component callback fired');

done_testing;