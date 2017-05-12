# 06.RoundedRect.t - Test the Gtk2::Ex::MindMapView::Border::RoundedRect
# -----------------------------------------------------------------------------

use Test::More tests => 38;

BEGIN {
chdir 't' if -d 't';
use lib '../lib';
use_ok( 'Gtk2::Ex::MindMapView' );
use_ok( 'Gtk2::Ex::MindMapView::Item' );
use_ok( 'Gtk2::Ex::MindMapView::ItemFactory' );
use_ok( 'Gtk2::Ex::MindMapView::Border::RoundedRect' );
use_ok( 'Gtk2::Ex::MindMapView::Border::Rectangle' );
use_ok( 'Gtk2::Ex::MindMapView::Border::Ellipse' );
}

diag( "Testing Gtk2::Ex::MindMapView::Border $Gtk2::Ex::MindMapView::Border::VERSION" );

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

my $border = $item1->get('border');

is( defined($border), 1, 'border should be defined');

isa_ok( $border, 'Gtk2::Ex::MindMapView::Border::RoundedRect');


my $content = $border->get('content');

is( defined($content), 1, 'content should be defined');

isa_ok($content, 'Gtk2::Ex::MindMapView::Content::EllipsisText');


my $x = $border->get('x');

is( $x, 0.0, 'x should be 0.0');


my $y = $border->get('y');

is( $y, 0.0, 'y should be 0.0');


my $height = $border->get('height');

is( $height, $benchmark_height, 'height should be ' . $benchmark_height);


my $width = $border->get('width');

is( $width, $benchmark_width, 'width should be ' . $benchmark_width);


my $radius = $border->get('radius');

is( $radius, 10, 'radius should be 10');


my $width_pixels = $border->get('width_pixels');

is( $width_pixels, 2.0, 'width_pixels should be 2.0');


my $padding_pixels = $border->get('padding_pixels');

is( $padding_pixels, 5.0, 'padding_pixels should be 5.0');



my $item2 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::Rectangle',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
	font_desc=>$font_desc,
	text=>$text);


isa_ok( $item2, 'Gtk2::Ex::MindMapView::Item');

$border = $item2->get('border');

is( defined($border), 1, 'border should be defined');

isa_ok( $border, 'Gtk2::Ex::MindMapView::Border::Rectangle');


$content = $border->get('content');

is( defined($content), 1, 'content should be defined');

isa_ok($content, 'Gtk2::Ex::MindMapView::Content::EllipsisText');


$x = $border->get('x');

is( $x, 0.0, 'x should be 0.0');


$y = $border->get('y');

is( $y, 0.0, 'y should be 0.0');


$height = $border->get('height');

is( $height, $benchmark_height, 'height should be ' . $benchmark_height);


$width = $border->get('width');

is( $width, $benchmark_width, 'width should be ' . $benchmark_width);


$width_pixels = $border->get('width_pixels');

is( $width_pixels, 2.0, 'width_pixels should be 2.0');


$padding_pixels = $border->get('padding_pixels');

is( $padding_pixels, 5.0, 'padding_pixels should be 5.0');



my $item3 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::Ellipse',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
	font_desc=>$font_desc,
	text=>$text);


isa_ok( $item3, 'Gtk2::Ex::MindMapView::Item');

$border = $item3->get('border');

is( defined($border), 1, 'border should be defined');

isa_ok( $border, 'Gtk2::Ex::MindMapView::Border::Ellipse');


$content = $border->get('content');

is( defined($content), 1, 'content should be defined');

isa_ok($content, 'Gtk2::Ex::MindMapView::Content::EllipsisText');


$x = $border->get('x');

is( $x, 0.0, 'x should be 0.0');


$y = $border->get('y');

is( $y, 0.0, 'y should be 0.0');


#my $height = $border->get('height');

#is( $height, $benchmark_height, 'height should be ' . $benchmark_height);


#my $width = $border->get('width');

#is( $width, $benchmark_width, 'width should be ' . $benchmark_width);


$width_pixels = $border->get('width_pixels');

is( $width_pixels, 2.0, 'width_pixels should be 2.0');


$padding_pixels = $border->get('padding_pixels');

is( $padding_pixels, 5.0, 'padding_pixels should be 5.0');




$item1->{border} = undef;

$item1->{hotspots} = undef;

$item1 = undef;

$factory->{view} = undef;

$factory = undef;

$view = undef;
