#!/usr/bin/perl
#TITLE: Gnome applet new
#REQUIRES: Gtk GdkImlib Gnome Applet
use Gtk::lazy;
use Gnome::Applet;

Gtk::Rc->parse_string(<<"EOF");
style "panel-font"
{
        font = "-adobe-helvetica-medium-r-normal--*-80-*-*-*-*-*-*"
		fg[NORMAL] = {0., 0., 1.}
}

widget "*AppletWidget.*GtkLabel" style "panel-font"
EOF

init Gnome::AppletWidget 'applet.pl';

$a = new Gnome::AppletWidget 'applet.pl';
$a->register_callback("du de dum", "hop hop", sub {
	print "yeppa\n";
});
$a->register_callback_dir("test", "dir");
$a->register_stock_callback("test/du de dam", "About", "hip hip", sub {
	print "yeppa 2\n";
});

$b = new Gtk::Button;
$b->set_name("testapplet");
$b->set_usize(50,50);
$label = new Gtk::Label "Button";
$b->add($label);

$a->add($b);
$a->show_all;


$a->signal_connect("change_orient", sub {
	my ($applet, $orient)  =@_;
	$label->set_text("Orient: $orient");
});

$a->signal_connect("back_change", sub {
	my ($applet, $type, $pixmap, $color) =@_;
	$label->set_text("Back: $type");
	if ($type == 1) {
		print "color: $color->{red} $color->{green} $color->{blue}\n";
	} elsif ($type == 2) {
		print "pixmap: $pixmap\n";
	}
});

$a->signal_connect("change_pixel_size", sub {
	my ($applet, $size) = @_;
	$label->set_text("Size: $size");
});

gtk_main Gnome::AppletWidget;
