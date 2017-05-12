# 04.Item.t - Test the Gtk2::Ex::MindMapView::Item
# -----------------------------------------------------------------------------

use Test::More tests => 22;

BEGIN {
chdir 't' if -d 't';
use lib '../lib';
use_ok( 'Gtk2::Ex::MindMapView' );
use_ok( 'Gtk2::Ex::MindMapView::Item' );
use_ok( 'Gtk2::Ex::MindMapView::ItemFactory' );
}

diag( "Testing Gtk2::Ex::MindMapView::Item $Gtk2::Ex::MindMapView::Item::VERSION" );

use Gtk2 '-init';

use constant BENCHMARK_INSET=>7;

my $text = 'Hello World!';

my $font_desc = Gtk2::Pango::FontDescription->from_string('Ariel Normal 10');

my $view = Gtk2::Ex::MindMapView->new(aa=>1);

my $factory = Gtk2::Ex::MindMapView::ItemFactory->new(view=>$view);

my $benchmark_text = Gnome2::Canvas::Item->new($view->root, 'Gnome2::Canvas::Text',
	font_desc=>$font_desc,
	text=>$text);

my $benchmark_x      = $benchmark_text->get('x');

my $benchmark_y      = $benchmark_text->get('y');

my $benchmark_height = $benchmark_text->get('text-height') + (BENCHMARK_INSET * 2);

my $benchmark_width  = $benchmark_text->get('text-width') + (BENCHMARK_INSET * 2);


my $item1 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
	font_desc=>$font_desc,
	text=>$text);

isa_ok( $item1, 'Gtk2::Ex::MindMapView::Item');


my $graph = $item1->get('graph');

is( $graph, undef, 'graph should be undefined');


my $column = $item1->get('column');

is( $column, undef, 'column should be undefined');


my $border = $item1->get('border');

is( defined($border), 1, 'border should be defined');

isa_ok( $border, 'Gtk2::Ex::MindMapView::Border::RoundedRect');


my $x = $item1->get('x');

is( $x, $benchmark_x, 'x should be ' . $benchmark_x);


my $y = $item1->get('y');

is( $y, $benchmark_y, 'y should be ' . $benchmark_y);


my $height = $item1->get('height');

is( $height, $benchmark_height, 'height should be ' . $benchmark_height);


my $width = $item1->get('width');

is( $width, $benchmark_width, 'width should be ' . $benchmark_width);


my $visible = $item1->get('visible');

is( $visible, 1, 'visible should be true');


my ($x1, $y1) = $item1->get_connection_point('left');

is( $x1, $benchmark_x, 'connection left x should be ' . $benchmark_x);

is( $y1, ($benchmark_height / 2), 'connection left y should be ' . ($benchmark_height / 2));


my ($x2, $y2) = $item1->get_connection_point('right');

is( $x2, $benchmark_width, 'connection right x should be ' . $benchmark_width);

is( $y2, ($benchmark_height / 2), 'connection right y should be ' . ($benchmark_height / 2));


my $hotspot1 = $item1->{hotspots}{'lower_left'};

isa_ok($hotspot1, 'Gtk2::Ex::MindMapView::HotSpot::Grip');


my $hotspot2 = $item1->{hotspots}{'lower_right'};

isa_ok($hotspot2, 'Gtk2::Ex::MindMapView::HotSpot::Grip');


my $hotspot3 = $item1->{hotspots}{'toggle_left'};

isa_ok($hotspot3, 'Gtk2::Ex::MindMapView::HotSpot::Toggle');


my $hotspot4 = $item1->{hotspots}{'toggle_right'};

isa_ok($hotspot4, 'Gtk2::Ex::MindMapView::HotSpot::Toggle');


my $weight = $item1->get_weight();

my $benchmark_weight = $benchmark_height * $benchmark_width;

is( $weight, $benchmark_weight, 'connection weight should be ' . $benchmark_weight);

$item1->{border} = undef;

$item1->{hotspots} = undef;

$item1 = undef;

$factory->{view} = undef;

$factory = undef;

$view = undef;
