# 03.Graph.t - Test Gtk2::Ex::MindMapView::Graph
# ----------------------------------------------------------------------------

use Test::More tests => 35;

BEGIN {
chdir 't' if -d 't';
use lib '../lib';
use_ok( 'Gtk2::Ex::MindMapView' );
use_ok( 'Gtk2::Ex::MindMapView::Item' );
use_ok( 'Gtk2::Ex::MindMapView::ItemFactory' );
use_ok( 'Gtk2::Ex::MindMapView::Graph' );
}

diag( "Testing Gtk2::Ex::MindMapView::Graph $Gtk2::Ex::MindMapView::Graph::VERSION" );

use Gtk2 '-init';

my $view = Gtk2::Ex::MindMapView->new(aa=>1);

my $factory = Gtk2::Ex::MindMapView::ItemFactory->new(view=>$view);

my $item1 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
	text=>'Hello World!');

my $graph = Gtk2::Ex::MindMapView::Graph->new();

isa_ok( $graph, 'Gtk2::Ex::MindMapView::Graph');

$graph->add($item1);

is( $graph->num_items(), 1, 'num_items() should return 1');
 
is( $graph->has_item($item1), 1, 'has_item() should return true');

is( scalar($graph->predecessors()), 0, 'predecessors() should be empty');

is( scalar($graph->successors()), 0, 'successors() should be empty');

is( $graph->get_root(), $item1, 'get_root() should return item1');

$graph->remove($item1);

is( $graph->num_items(), 0, 'num_items() should return 0');
 
is( $graph->has_item($item1), '', 'has_item() should return false');

is( scalar($graph->predecessors()), 0, 'predecessors() should be empty');

is( scalar($graph->successors()), 0, 'successors() should be empty');

is( $graph->get_root(), undef, 'get_root() should return undef');

my $item2 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
	text=>'Sunny Day');

my $item3 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
	text=>'Cloudy Day');

$graph->add($item1);

$graph->add($item1, $item2);

$graph->add($item1, $item3);

is( $graph->num_items(), 3, 'num_items() should return 3');
 
is( $graph->has_item($item1), 1, 'has_item($item1) should return true');

is( $graph->has_item($item2), 1, 'has_item($item2) should return true');

is( $graph->has_item($item3), 1, 'has_item($item3) should return true');

is( scalar($graph->predecessors($item1)), 0, 'predecessors($item1) should be empty');

is( scalar($graph->successors($item1)), 2, 'successors() should be two items');

is( scalar($graph->predecessors($item2)), 1, 'predecessors($item2) should return 1 predecessor');

is( ($graph->predecessors($item2))[0], $item1, 'predecessors($item2) should be $item1');

is( scalar($graph->successors($item2)), 0, 'successors() should be empty');

is( scalar($graph->predecessors($item3)), 1, 'predecessors($item3) should return 1 predecessor');

is( ($graph->predecessors($item3))[0], $item1, 'predecessors($item3) should be $item1');

is( scalar($graph->successors($item3)), 0, 'successors() should be empty');

is( $graph->get_root(), $item1, 'get_root() should return item1');

$graph->set_root($item3);

is( $graph->get_root(), $item3, 'get_root() should return item3');

is( scalar($graph->successors($item3)), 1, 'successors($item3) should return 1 successor');

is( scalar($graph->predecessors($item3)), 0, 'predecessors($item3) should be empty');

is( ($graph->successors($item3))[0], $item1, 'predecessors($item3) should be $item1');

is( scalar($graph->successors($item1)), 1, 'successors($item1) should return 1 successor');

is( scalar($graph->predecessors($item1)), 1, 'predecessors($item1) should return 1 successor');

is( ($graph->successors($item1))[0], $item2, 'predecessors($item1) should be $item2');

$graph = undef;

$item1->{border} = undef;

$item1->{hotspots} = undef;

$item1 = undef;

$item2->{border} = undef;

$item2->{hotspots} = undef;

$item2 = undef;

$item3->{border} = undef;

$item3->{hotspots} = undef;

$item3 = undef;

$factory->{view} = undef;

$factory = undef;

$view = undef;
