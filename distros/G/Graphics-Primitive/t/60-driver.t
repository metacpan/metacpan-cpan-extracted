use lib 't/lib', 'lib';
use strict;

use Test::More tests => 4;

use Graphics::Primitive::Component;
use Graphics::Primitive::Container;

BEGIN {
    use_ok('Graphics::Primitive::Driver');
    use_ok('DummyDriver');
}

my $driver = DummyDriver->new;
isa_ok($driver, 'DummyDriver');

my $container = Graphics::Primitive::Container->new;
my $comp = Graphics::Primitive::Component->new;
$container->add_component($comp, 'c');

$driver->prepare($container);
$driver->finalize($container);
$driver->draw($container);
cmp_ok($driver->draw_component_called, '==', 2, 'component draws');

