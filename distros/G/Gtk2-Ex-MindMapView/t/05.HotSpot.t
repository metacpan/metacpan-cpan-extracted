# 05.HotSpot.t - Test the Gtk2::Ex::MindMapView::HotSpot.
# -----------------------------------------------------------------------------

use Test::More tests => 24;

BEGIN {
chdir 't' if -d 't';
use lib '../lib';
use_ok( 'Gtk2::Ex::MindMapView' );
use_ok( 'Gtk2::Ex::MindMapView::Item' );
use_ok( 'Gtk2::Ex::MindMapView::ItemFactory' );
}

diag( "Testing Gtk2::Ex::MindMapView::HotSpot $Gtk2::Ex::MindMapView::HotSpot::VERSION" );

use Gtk2 '-init';

my $view = Gtk2::Ex::MindMapView->new(aa=>1);

my $factory = Gtk2::Ex::MindMapView::ItemFactory->new(view=>$view);

my $item1 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
	text=>'Hello World!');

isa_ok( $item1, 'Gtk2::Ex::MindMapView::Item');

my $white  = Gtk2::Gdk::Color->parse('white');

my $gray   = Gtk2::Gdk::Color->parse('gray');

my $orange = Gtk2::Gdk::Color->parse('orange');


my $hotspot1 = $item1->{hotspots}{'lower_left'};

isa_ok($hotspot1, 'Gtk2::Ex::MindMapView::HotSpot');

is($hotspot1->{fill_color_gdk}->equal($white), 1, 'fill_color_gdk should be white');

is($hotspot1->{outline_color_gdk}->equal($white), 1, 'outline_color_gdk should be white');

is($hotspot1->{hotspot_color_gdk}->equal($orange), 1, 'hotspot_color_gdk should be orange');


my $hotspot2 = $item1->{hotspots}{'lower_right'};

isa_ok($hotspot2, 'Gtk2::Ex::MindMapView::HotSpot');

is($hotspot2->{fill_color_gdk}->equal($orange), 1, 'fill_color_gdk should be white');

is($hotspot2->{outline_color_gdk}->equal($white), 1, 'outline_color_gdk should be white');

is($hotspot2->{hotspot_color_gdk}->equal($orange), 1, 'hotspot_color_gdk should be orange');



my $hotspot3 = $item1->{hotspots}{'toggle_left'};

isa_ok($hotspot3, 'Gtk2::Ex::MindMapView::HotSpot');

is($hotspot3->{fill_color_gdk}->equal($white), 1, 'fill_color_gdk should be white');

is($hotspot3->{outline_color_gdk}->equal($gray), 1, 'outline_color_gdk should be gray');

is($hotspot3->{hotspot_color_gdk}->equal($orange), 1, 'hotspot_color_gdk should be orange');



my $hotspot4 = $item1->{hotspots}{'toggle_right'};

isa_ok($hotspot4, 'Gtk2::Ex::MindMapView::HotSpot');

is($hotspot4->{fill_color_gdk}->equal($white), 1, 'fill_color_gdk should be white');

is($hotspot4->{outline_color_gdk}->equal($gray), 1, 'outline_color_gdk should be gray');

is($hotspot4->{hotspot_color_gdk}->equal($orange), 1, 'hotspot_color_gdk should be orange');


my $image1 = $hotspot1->{image};

isa_ok($image1, 'Gnome2::Canvas::Shape');


my $image2 = $hotspot2->{image};

isa_ok($image2, 'Gnome2::Canvas::Shape');


my $image3 = $hotspot3->{image};

isa_ok($image3, 'Gnome2::Canvas::Ellipse');


my $image4 = $hotspot4->{image};

isa_ok($image4, 'Gnome2::Canvas::Ellipse');


$item1->{border} = undef;

$item1->{hotspots} = undef;

$item1 = undef;

$factory->{view} = undef;

$factory = undef;

$view = undef;
