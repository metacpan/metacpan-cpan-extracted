use Gtk;

#TITLE: Simple #5
#REQUIRES: Gtk

init Gtk;

Gtk->timeout_add(1000, sub { Gtk->gc; return 1; });

#Gtk->gc;
                 
{
	my($window,$button);

$window = new Gtk::Widget	"GtkWindow",
		type			=>	-toplevel,
		title		=>	"hello world",
		allow_grow		=>	0,
		allow_shrink		=>	0,
		border_width	=>	10;


#show $window;
destroy $window;

}

main Gtk;

