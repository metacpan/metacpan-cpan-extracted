# 07.Content.t - Test the Gtk2::Ex::MindMapView::Content
# -----------------------------------------------------------------------------

use Test::More tests => 36;

BEGIN {
chdir 't' if -d 't';
use lib '../lib';
use_ok( 'Gtk2::Ex::MindMapView' );
use_ok( 'Gtk2::Ex::MindMapView::Item' );
use_ok( 'Gtk2::Ex::MindMapView::ItemFactory' );
use_ok( 'Gtk2::Ex::MindMapView::Content::EllipsisText' );
}

diag( "Testing Gtk2::Ex::MindMapView::Content::EllipsisText $Gtk2::Ex::MindMapView::Content::EllipsisText::VERSION" );

use Gtk2 '-init';

use constant BENCHMARK_INSET=>7;

my $text = 'Hello World!';

my $view = Gtk2::Ex::MindMapView->new(aa=>1);

my $factory = Gtk2::Ex::MindMapView::ItemFactory->new(view=>$view);

my $font_desc = Gtk2::Pango::FontDescription->from_string('Ariel Normal 10');

my $benchmark_text = Gnome2::Canvas::Item->new($view->root, 'Gnome2::Canvas::Text',
	font_desc=>$font_desc,
	text=>$text);

my $benchmark_x      = $benchmark_text->get('x') + BENCHMARK_INSET;

my $benchmark_y      = $benchmark_text->get('y') + BENCHMARK_INSET;

my $benchmark_height = $benchmark_text->get('text-height');

my $benchmark_width  = $benchmark_text->get('text-width');

my $item1 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
	font_desc=>$font_desc,
	text=>$text);

isa_ok( $item1, 'Gtk2::Ex::MindMapView::Item');

my $border = $item1->get('border');

is( defined($border), 1, 'item1: border should be defined');

isa_ok( $border, 'Gtk2::Ex::MindMapView::Border::RoundedRect');

my $content = $border->get('content');

is( defined($content), 1, 'item1: content should be defined');

isa_ok( $content, 'Gtk2::Ex::MindMapView::Content::EllipsisText');

my $x = $content->get('x');

is( $x, $benchmark_x, 'item1: x should be ' . $benchmark_x);


my $y = $content->get('y');

is( $y, $benchmark_y, 'item1: y should be ' . $benchmark_y);


my $height = $content->get('height');

is( $height, $benchmark_height, 'item1: height should be ' . $benchmark_height);


my $width = $content->get('width');

is( $width, $benchmark_width, 'item1: width should be ' . $benchmark_width);


my $etext = $content->get('text');

is( $etext, "Hello World!", 'item1: text should be "Hello World!"');


my $black = Gtk2::Gdk::Color->parse('black');

my $text_color_gdk = $content->get('text_color_gdk');

is( $text_color_gdk->equal($black), 1, 'item1: text_color_gdk should be black');



my $item2 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::Rectangle',
	content=>'Gtk2::Ex::MindMapView::Content::Uri',
	font_desc=>$font_desc,
	text=>$text,
	uri=>'http://www.google.com',
        browser=>'/usr/bin/firefox');

isa_ok( $item2, 'Gtk2::Ex::MindMapView::Item');

$border = $item2->get('border');

is( defined($border), 1, 'item2: border should be defined');

isa_ok( $border, 'Gtk2::Ex::MindMapView::Border::Rectangle');

$content = $border->get('content');

is( defined($content), 1, 'item2: content should be defined');

isa_ok( $content, 'Gtk2::Ex::MindMapView::Content::Uri');

$x = $content->get('x');

is( $x, $benchmark_x, 'item2: x should be ' . $benchmark_x);


$y = $content->get('y');

is( $y, $benchmark_y, 'item2: y should be ' . $benchmark_y);


$height = $content->get('height');

is( $height, $benchmark_height, 'item2: height should be ' . $benchmark_height);


$width = $content->get('width');

is( $width, $benchmark_width, 'item2: width should be ' . $benchmark_width);


$etext = $content->get('text');

is( $etext, "Hello World!", 'item2: text should be "Hello World!"');


$euri = $content->get('uri');

is( $euri, "http://www.google.com", 'item2: URI should be "http://www.google.com"');


$black = Gtk2::Gdk::Color->parse('black');

$text_color_gdk = $content->get('text_color_gdk');

is( $text_color_gdk->equal($black), 1, 'item2: text_color_gdk should be black');


my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file('./monalisa.jpeg');

my $pixbuf_height = $pixbuf->get_height();

my $pixbuf_width = $pixbuf->get_width();

my $item3 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::Rectangle',
	content=>'Gtk2::Ex::MindMapView::Content::Picture',
        pixbuf=>$pixbuf);

isa_ok( $item3, 'Gtk2::Ex::MindMapView::Item');

$border = $item3->get('border');

is( defined($border), 1, 'item3: border should be defined');

isa_ok( $border, 'Gtk2::Ex::MindMapView::Border::Rectangle');

$content = $border->get('content');

is( defined($content), 1, 'item3: content should be defined');

isa_ok( $content, 'Gtk2::Ex::MindMapView::Content::Picture');

$x = $content->get('x');

is( $x, $benchmark_x, 'item3: x should be ' . $benchmark_x);


$y = $content->get('y');

is( $y, $benchmark_y, 'item3: y should be ' . $benchmark_y);


$height = $content->get('height');

is( $height, $pixbuf_height, 'item3: height should be ' . $pixbuf_height);


$width = $content->get('width');

is( $width, $pixbuf_width, 'item3: width should be ' . $pixbuf_width);




$item1->{border} = undef;

$item1->{hotspots} = undef;

$item1 = undef;

$factory->{view} = undef;

$factory = undef;

$view = undef;
