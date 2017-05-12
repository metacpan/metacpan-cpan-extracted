use Test::More tests => 1;

BEGIN {
chdir 't' if -d 't';
use lib '../lib';
use_ok( 'Gtk2::Ex::MindMapView' );
}

diag( "Testing Gtk2::Ex::MindMapView $Gtk2::Ex::MindMapView::VERSION" );
