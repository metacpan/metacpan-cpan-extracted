use Gtk;

#TITLE: Simple #2
#REQUIRES: Gtk

use vars qw($window $button $button2);

init Gtk;

Gtk->timeout_add(1000, sub { 
	destroy $window;
	Gtk->gc;
	$window = undef;
	Gtk->gc;
	 return 0; 
});

Gtk->gc;
                 
$window = new Gtk::Widget	"GtkWindow",
		GtkWindow::type			=>	-toplevel,
		GtkWindow::title		=>	"hello world",
		GtkWindow::allow_grow		=>	0,
		GtkWindow::allow_shrink		=>	0,
		GtkContainer::border_width	=>	10;

Gtk->gc;

show $window;

main Gtk;


