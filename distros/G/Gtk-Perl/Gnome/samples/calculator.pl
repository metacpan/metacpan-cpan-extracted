#!/usr/bin/perl

#TITLE: Gnome Calculator
#REQUIRES: Gtk Gnome

$NAME = 'Calculator';

use Gnome;
init Gnome "calculator.pl";

my($window) = new Gtk::Widget "Gtk::Window",
	-type => -toplevel,
	-visible => 1,
	-signal::destroy => sub {exit}
	;

my($calculator) = new_child $window "Gnome::Calculator",
	-visible => 1
	;

main Gtk;
