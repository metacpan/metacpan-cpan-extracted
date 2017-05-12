use Gtk;

#TITLE: Simple #3
#REQUIRES: Gtk

init Gtk;

#Gtk->timeout_add(1000, sub { Gtk->gc; return 1; });

#Gtk->gc;
                 
{
	my($window,$button);

$window = new Gtk::Widget	"GtkWindow",
		type			=>	-toplevel,
		title		=>	"hello world",
		allow_grow		=>	0,
		allow_shrink		=>	0,
		border_width	=>	10;

$button = new Gtk::Widget	"Gtk::Button",
		label		=>	"hello world",
		-clicked	=>	sub { destroy $button; destroy $window; },
		parent		=>	$window,
		visible		=>	1;

show $window;
}

main Gtk;

