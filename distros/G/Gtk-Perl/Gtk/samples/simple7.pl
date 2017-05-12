
use Gnome;

init Gnome "App_id";

#TITLE: Simple #7
#REQUIRES: Gtk Gnome

$app = new Gnome::App "appname", "title";

$button = new Gtk::Button "button";

$button->signal_connect (clicked => sub {
	my($w) = new Gnome::MessageBox "message", "messagebox_type", "button1", "button2";
	$w->signal_connect(clicked => sub {
		print "Button $_[1] clicked\n";
	});
	#$w->set_modal;
	show $w;
});

show $button;

$vbox = new Gtk::VBox 0, 1;
show $vbox;

$vbox->pack_start($button, 1, 1, 1);

eval {
	$calc = new Gnome::Calculator;
	show $calc;
	$vbox->pack_start($calc, 1, 1, 1);
};

eval {
	$date = new Gnome::DateEdit time(), 1, 0;
	show $date;
	$vbox->pack_start($date, 1, 1, 1);
};

$app->set_contents($vbox);

show $app;

main Gtk;

