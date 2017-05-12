# 02.ItemFactory.t - Test the Gtk2::Ex::MindMapView::ItemFactory.
# -----------------------------------------------------------------------------
use Test::More tests => 17;

BEGIN {
chdir 't' if -d 't';
use lib '../lib';
use_ok( 'Gtk2::Ex::MindMapView' );
use_ok( 'Gtk2::Ex::MindMapView::Item' );
use_ok( 'Gtk2::Ex::MindMapView::ItemFactory' );
}

diag( "Testing Gtk2::Ex::MindMapView::ItemFactory $Gtk2::Ex::MindMapView::ItemFactory::VERSION" );

use Gtk2 '-init';

my $view = Gtk2::Ex::MindMapView->new(aa=>1);

isa_ok( $view, 'Gtk2::Ex::MindMapView');

my $factory = Gtk2::Ex::MindMapView::ItemFactory->new(view=>$view);

isa_ok( $factory, 'Gtk2::Ex::MindMapView::ItemFactory');

is( defined($factory->{view}), 1, 'Factory view is defined');

isa_ok( $factory->{view}, 'Gtk2::Ex::MindMapView');

my $white  = Gtk2::Gdk::Color->parse('white');

my $black  = Gtk2::Gdk::Color->parse('black');

my $gray   = Gtk2::Gdk::Color->parse('gray');

my $orange = Gtk2::Gdk::Color->parse('orange');

is( $factory->{fill_color_gdk}->equal($white), 1, 'Fill_color_gdk is white');

is( $factory->{outline_color_gdk}->equal($gray), 1, 'Outline_color_gdk is gray');

is( $factory->{text_color_gdk}->equal($black), 1, 'Text_color_gdk is black');

is( $factory->{hotspot_color_gdk}->equal($orange), 1, 'Hotspot_color_gdk is orange');

my $item1 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
	text=>'Hello World!');

isa_ok( $item1, 'Gtk2::Ex::MindMapView::Item');

is( $item1->{graph}, undef, 'Graph should be undefined');

is( $item1->{column}, undef, 'Column should be undefined');

is( defined($item1->{border}), 1, 'Border should be defined');

isa_ok($item1->{border}, 'Gtk2::Ex::MindMapView::Border::RoundedRect');

is( defined($item1->{visible}), 1, 'Item should be visible');

$item1->{border} = undef;

$item1->{hotspots} = undef;

$item1 = undef;

$factory->{view} = undef;

$factory = undef;

$view = undef;
