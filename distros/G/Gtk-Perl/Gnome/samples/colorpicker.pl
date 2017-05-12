#!/usr/bin/perl

$NAME = 'Color Picker';

use Gnome;

init Gnome "colorpicker.pl";

$w = new Gtk::Window -toplevel;

$cp = new Gnome::ColorPicker;

show $cp;

$w->add($cp);

show $w;

main Gtk;
