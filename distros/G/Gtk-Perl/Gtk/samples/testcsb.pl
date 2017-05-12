#!/usr/local/bin/perl -w

#TITLE: ColorSelectButton
#REQUIRES: Gtk

use Gtk;
use Gtk::ColorSelectButton;

Gtk->init;

init Gtk::ColorSelectButton;

$mw     = Gtk::Widget->new("GtkWindow",
			   -type   =>	'toplevel',
			   -title  =>   "Color chooser");

$vbox = Gtk::VBox->new(0,1);

$hbox   = Gtk::HBox->new(0,1);

$button = Gtk::Label->new("Color:");
$button->show();
$hbox->pack_start($button, 10,10,10);

$color_button = Gtk::ColorSelectButton->new(-width=>100,-height=>10);
$hbox->pack_start($color_button, 1,1,0);
$color_button->show();

$hbox->show();

$vbox->pack_start($hbox, 1,1,10);

$color_button->set('color' => "1 90 199");

# Quit button
$button_quit = Gtk::Widget->new("GtkButton",
				-label   => "Quit",
				-clicked => sub {
				    print "Color chosen: ",$color_button->color,"\n";
				    exit;
				},
			        -visible=>1);
$vbox->pack_start($button_quit, 1,1,0);
$vbox->show();

$mw->add($vbox);
$mw->show;

Gtk->main;

