use Gtk;

use vars qw($window $button $button2);

sub hello {
	Gtk->print("hello world\n");
	print "Destroying $button and $window\n";
	destroy $button;
	destroy $window;
}

init Gtk;

$window = new Gtk::Widget	"GtkWindow",
		GtkObject::user_data		=>	undef,
		GtkWindow::type			=>	-toplevel,
		GtkWindow::title		=>	"hello world",
		GtkWindow::allow_grow		=>	0,
		GtkWindow::allow_shrink		=>	0,
		GtkContainer::border_width	=>	10;

$button = new Gtk::Widget	"GtkButton",
		GtkButton::label		=>	"hello world",
		GtkObject::signal::clicked	=>	"hello",
		GtkWidget::parent		=>	$window,
		GtkWidget::visible		=>	1;

show $window;

main Gtk;

