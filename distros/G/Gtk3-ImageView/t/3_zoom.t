use warnings;
use strict;
use Test::More tests => 7;
use Test::Deep;

BEGIN {
    use Glib qw/TRUE FALSE/;
    use Gtk3 -init;
    use_ok('Gtk3::ImageView');
}

my $window = Gtk3::Window->new('toplevel');
$window->set_size_request( 300, 200 );
my $view  = Gtk3::ImageView->new;
my $scale = $view->get('scale-factor');
$window->add($view);
$window->show_all;
$view->set_pixbuf( Gtk3::Gdk::Pixbuf->new_from_file('t/bigpic.svg'), TRUE );
cmp_deeply( $view->get_zoom, num( 0.2 * $scale, 0.0001 ), 'shrinked' );
$view->set_zoom(1);

# the transp-green picture is 100x100 which is less than 200.
$view->set_pixbuf( Gtk3::Gdk::Pixbuf->new_from_file('t/transp-green.svg'),
    FALSE );
is( $view->get_zoom, 1, 'picture fully visible' );
$view->set_pixbuf( Gtk3::Gdk::Pixbuf->new_from_file('t/transp-green.svg'),
    TRUE );
is( $view->get_zoom, 2 * $scale, 'zoomed' );
$view->set_fitting(TRUE);
is( $view->get_zoom, $scale, 'no need to zoom' );
$view->set_pixbuf( Gtk3::Gdk::Pixbuf->new_from_file('t/transp-green.svg'),
    TRUE );
is( $view->get_zoom, $scale, 'no need to zoom even when TRUE' );
$view->set_pixbuf( Gtk3::Gdk::Pixbuf->new_from_file('t/bigpic.svg'), TRUE );
cmp_deeply( $view->get_zoom, num( 0.2 * $scale, 0.0001 ), 'still shrinked' );
