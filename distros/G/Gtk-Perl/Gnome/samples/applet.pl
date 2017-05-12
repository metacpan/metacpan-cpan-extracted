#!/usr/bin/perl

#TITLE: Gnome applet
#REQUIRES: Gtk Gnome

use Gnome;

init Gnome::Panel::AppletWidget 'applet.pl';

$a = new Gnome::Panel::AppletWidget 'applet.pl';
realize $a;

$b = new Gtk::Button "Button";
$b->set_usize(50,50);
show $b;

$a->add($b);
show $a;

gtk_main Gnome::Panel::AppletWidget;
