use Test::More tests => 22;

use Geometry::Primitive::Point;
use Layout::Manager::Compass;
use Layout::Manager::Single;
use Graphics::Primitive::Container;
use Graphics::Primitive::Component;

BEGIN {
    use_ok('Layout::Manager::Compass');
}

my $legend = new Graphics::Primitive::Component(
    minimum_height => 10, minimum_width => 10
);
my $yaxis = new Graphics::Primitive::Component(
    minimum_height => 10, minimum_width => 20
);
my $xaxis = new Graphics::Primitive::Component(
    minimum_height => 20, minimum_width => 10
);
my $plot = new Graphics::Primitive::Container(
    minimum_height => 10, minimum_width => 10,
    layout_manager => Layout::Manager::Single->new
);
my $renderer = new Graphics::Primitive::Component(
    minimum_height => 10, minimum_width => 10,
);
$plot->add_component($renderer);

my $cont = new Graphics::Primitive::Container(
    width => 500, height => 300
);

$cont->add_component($legend, 's');
$cont->add_component($xaxis, 's');
$cont->add_component($yaxis, 'w');
$cont->add_component($plot, 'c');

cmp_ok($cont->component_count, '==', 4, 'component_count');

my $lm = Layout::Manager::Compass->new;
$lm->do_layout($cont);

cmp_ok($legend->origin->x, '==', 0, 'legend origin x');
cmp_ok($legend->origin->y, '==', 290, 'legend origin y');
cmp_ok($legend->width, '==', 500, 'legend width');
cmp_ok($legend->height, '==', 10, 'north height');

cmp_ok($yaxis->origin->x, '==', 0, 'yaxis origin x');
cmp_ok($yaxis->origin->y, '==', 0, 'yaxis origin y');
cmp_ok($yaxis->width, '==', 20, 'yaxis width');
cmp_ok($yaxis->height, '==', 270, 'yaxis height');

cmp_ok($xaxis->origin->x, '==', 0, 'xaxis origin x');
cmp_ok($xaxis->origin->y, '==', 270, 'xaxis origin y');
cmp_ok($xaxis->width, '==', 500, 'xaxis width');
cmp_ok($xaxis->height, '==', 20, 'xaxis height');

cmp_ok($plot->origin->x, '==', 20, 'plot origin x');
cmp_ok($plot->origin->y, '==', 0, 'plot origin y');
cmp_ok($plot->width, '==', 480, 'plot width');
cmp_ok($plot->height, '==', 270, 'plot height');

cmp_ok($renderer->origin->x, '==', 0, 'renderer origin x');
cmp_ok($renderer->origin->y, '==', 0, 'renderer origin y');
cmp_ok($renderer->width, '==', $plot->width, 'renderer width');
cmp_ok($renderer->height, '==', $plot->height, 'renderer width');