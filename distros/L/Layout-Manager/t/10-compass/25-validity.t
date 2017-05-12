use Test::More tests => 4;

use lib qw(t/lib lib);

use DummyDriver;

use Geometry::Primitive::Point;
use Graphics::Primitive::Component;
use Graphics::Primitive::Container;

BEGIN {
    use_ok('Layout::Manager::Compass');
}

my $foo = Graphics::Primitive::Component->new(
    name => 'one', minimum_height => 20, minimum_width => 20
);
my $foo2 = Graphics::Primitive::Component->new(
    name => 'two', minimum_height => 20, minimum_width => 20
);
my $foo3 = Graphics::Primitive::Component->new(
    name => 'three', minimum_height => 20, minimum_width => 20
);

my $cont = Graphics::Primitive::Container->new(
    width => 100, height => 40
);

$cont->add_component($foo, 'n');
$cont->add_component($foo2, 'e');
$cont->add_component($foo3, 'c');

cmp_ok($cont->component_count, '==', 3, 'component count');

my $driver = new DummyDriver;
$driver->prepare($cont);

my $lm = Layout::Manager::Compass->new;
$lm->do_layout($cont);

my $cont2 = Graphics::Primitive::Container->new(
    width => 100, height => 40,
    layout_manager => Layout::Manager::Compass->new
);
my $foo4 = Graphics::Primitive::Component->new(
    name => 'four', minimum_height => 20, minumim_width => 20
);
$cont2->add_component($foo4, 'c');
$cont->add_component($cont2, 'w');

my $ret2 = $lm->do_layout($cont);
cmp_ok($ret2, '==', 1, 'layout executed');

$foo4->width(21);
my $ret4 = $lm->do_layout($cont);
cmp_ok($ret4, '==', 1, 'layout executed');

