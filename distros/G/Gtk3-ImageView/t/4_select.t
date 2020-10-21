use warnings;
use strict;
use Try::Tiny;
use File::Temp;
use Test::More tests => 2;
use Test::MockObject;
use Carp::Always;

BEGIN {
    use Glib qw/TRUE FALSE/;
    use Gtk3 -init;
    use_ok('Gtk3::ImageView');
}

#########################

my $window = Gtk3::Window->new('toplevel');
$window->set_size_request( 300, 200 );
my $view = Gtk3::ImageView->new;
$window->add($view);
$view->set_tool('selector');
$view->set_pixbuf( Gtk3::Gdk::Pixbuf->new_from_file('t/transp-green.svg'),
    TRUE );
$window->show_all;
$window->hide;

$view->set_zoom(8);
my $event = Test::MockObject->new;
$event->set_always( 'button', 0 );
$event->set_always( 'x',      7 );
$event->set_always( 'y',      5 );
$view->get_tool->button_pressed($event);
$event->set_always( 'x', 93 );
$event->set_always( 'y', 67 );
$view->get_tool->button_released($event);
is_deeply( $view->get_selection, { x => 32, y => 38, width => 11, height => 8 },
    'get_selection' );

