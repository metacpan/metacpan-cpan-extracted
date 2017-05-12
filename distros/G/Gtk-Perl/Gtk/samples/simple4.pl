use Gtk;

init Gtk;

#TITLE: Simple #4
#REQUIRES: Gtk

{
	my($window,$button);

$button = new Gtk::Widget	"GtkButton",
		GtkButton::label		=>	"hello world",
		GtkWidget::visible		=>	1;
}

main Gtk;

