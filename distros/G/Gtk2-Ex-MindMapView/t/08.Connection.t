# 08.Connection.t - Test the Gtk2::Ex::MindMapView::Connection
# -----------------------------------------------------------------------------
use Test::More tests => 10;

BEGIN {
chdir 't' if -d 't';
use lib '../lib';
use_ok( 'Gtk2::Ex::MindMapView' );
use_ok( 'Gtk2::Ex::MindMapView::Item' );
use_ok( 'Gtk2::Ex::MindMapView::ItemFactory' );
}

diag( "Testing Gtk2::Ex::MindMapView::Connection $Gtk2::Ex::MindMapView::Connection::VERSION" );

use Gtk2 '-init';

my $view = Gtk2::Ex::MindMapView->new(aa=>1);

my $factory = Gtk2::Ex::MindMapView::ItemFactory->new(view=>$view);

my $item1 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
	text=>'Item One');

isa_ok( $item1, 'Gtk2::Ex::MindMapView::Item');

$view->add_item( $item1);

my $item2 = $factory->create_item(
	border=>'Gtk2::Ex::MindMapView::Border::RoundedRect',
	content=>'Gtk2::Ex::MindMapView::Content::EllipsisText',
	text=>'Item Two');

isa_ok( $item2, 'Gtk2::Ex::MindMapView::Item');

$view->add_item( $item1, $item2);

my @connections = @{$view->{connections}{$item2}};

foreach my $connection (@connections)
{
    isa_ok($connection, 'Gtk2::Ex::MindMapView::Connection');

    my $predecessor_item = $connection->{predecessor_item};

    isa_ok($predecessor_item, 'Gtk2::Ex::MindMapView::Item');

    my $item = $connection->{item};

    isa_ok($item, 'Gtk2::Ex::MindMapView::Item');

    my $predecessor_signal_id = $connection->{predecessor_signal_id};

    is(defined($predecessor_signal_id), 1, 'Predecessor signal id must be defined');

    my $item_signal_id = $connection->{item_signal_id};

    is(defined($item_signal_id), 1, 'Item signal id must be defined');
}

$item1->{border} = undef;

$item1->{hotspots} = undef;

$item1 = undef;

$factory->{view} = undef;

$factory = undef;

$view = undef;
