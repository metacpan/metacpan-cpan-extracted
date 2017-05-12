use Gtk;

# TITLE: Simple #1
# REQUIRES: Gtk

use vars qw($window $button $button2);

sub hello {
	Gtk->print("hello world\n");
	print "Destroying $button and $window\n";
	destroy $button;
	destroy $window;
	$button = undef;
	$window = undef;
}

init Gtk;

$window = new Gtk::Widget	"GtkWindow",
		GtkWindow::type			=>	-toplevel,
		GtkWindow::title		=>	"hello world",
		GtkWindow::allow_grow		=>	0,
		GtkWindow::allow_shrink		=>	0,
		GtkContainer::border_width	=>	10;

#$button = new Gtk::Widget	"GtkButton",
#		GtkButton::label		=>	"hello world",
#		GtkObject::signal::clicked	=>	"hello",
#		GtkWidget::parent		=>	$window,
#		GtkWidget::visible		=>	1;

$button = new_child $window "GtkButton",
		GtkButton::label		=>	"hello world",
		GtkObject::signal::clicked	=>	"hello",
		GtkWidget::visible		=>	1;

show $window;

main Gtk;

