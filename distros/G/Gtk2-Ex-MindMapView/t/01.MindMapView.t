# Test instantiation of Gtk2::Ex::MindMapView
# ---------------------------------------------------------------------

use Test::More tests => 9;

BEGIN {
chdir 't' if -d 't';
use lib '../lib';
use_ok( 'Gtk2::Ex::MindMapView' );
}

diag( "Testing Gtk2::Ex::MindMapView $Gtk2::Ex::MindMapView::VERSION" );

use Gtk2 '-init';

my $view1 = Gtk2::Ex::MindMapView->new();

isa_ok( $view1, 'Gtk2::Ex::MindMapView');

is( defined($view1->{graph}), 1, 'Graph is defined.');

isa_ok( $view1->{graph}, 'Gtk2::Ex::MindMapView::Graph');

is($view1->get('aa'), 0, 'Anti-aliasing is not enabled');

my $view2 = Gtk2::Ex::MindMapView->new(aa=>1);

isa_ok( $view2, 'Gtk2::Ex::MindMapView');

is($view2->get('aa'), 1, 'Anti-aliasing is enabled');

my $view3 = Gtk2::Ex::MindMapView->new(aa=>0);

isa_ok( $view3, 'Gtk2::Ex::MindMapView');

is($view3->get('aa'), 0, 'Anti-aliasing is not enabled');
