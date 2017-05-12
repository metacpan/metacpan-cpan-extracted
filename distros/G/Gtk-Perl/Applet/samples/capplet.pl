#!/usr/bin/perl

#TITLE: Gnome capplet
#REQUIRES: Gtk Gnome Applet

use Gnome::Applet;

init Gnome::CappletWidget 'capplet.pl';

$a = new Gnome::CappletWidget;
$b = new Gtk::Button "Button";
$b->set_usize(50,50);
show $b;

$a->add($b);
show $a;

gtk_main Gnome::CappletWidget;
