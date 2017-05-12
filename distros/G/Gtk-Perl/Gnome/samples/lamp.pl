#!/usr/bin/perl

$NAME = 'Lamp';

use Gnome;

init Gnome "colorpicker.pl";

$w = new Gtk::Window -toplevel;

$v = new Gtk::VBox 0, 0;
show $v;



$h = new Gtk::HBox 0, 0;

$lamp1 = new Gnome::Lamp;
show $lamp1;


$h->pack_start($lamp1, 1, 1, 0);
show $h;

$lamp2 = new Gnome::Lamp;
$lamp2->set_type('busy');
show $lamp2;

$h->pack_start($lamp2, 1, 1, 0);

$lamp3 = new Gnome::Lamp;
$lamp3->set_sequence("RGBYAP");
show $lamp3;

$h->pack_start($lamp3, 1, 1, 0);

$v->pack_start($h, 1, 1, 0);

$label = new Gtk::Label "Pick color:";
show $label;
$v->pack_start($label, 1, 1, 0);

$cp = new Gnome::ColorPicker;
show $cp;

$v->pack_start($cp, 1, 1, 0);

$cp->signal_connect( color_set => sub {
	my($c, $r, $g, $b, $a) = @_;
	$lamp1->set_color({red => $r, green => $g, blue => $b});
});

$cp->set_d(.5, .5, .5, .5);

$w->add($v);

show $w;

main Gtk;
