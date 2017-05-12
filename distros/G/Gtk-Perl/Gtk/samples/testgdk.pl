use Gtk::Gdk;

#TITLE: Raw Gdk
#REQUIRES: Gdk

init Gtk::Gdk;

$window = new Gtk::Gdk::Window	{title => "title", width => 100, height => 100, "window_type" => -toplevel, event_mask => undef};
$window->show;

while(1) {
	Gtk::Gdk->event_get;
}