#!/usr/bin/perl

#TITLE: Gnome About
#REQUIRES: Gtk Gnome

$NAME = 'About';

use Gnome;

init Gnome "about.pl";

$about = new Gnome::About "Title", "Version", "Copyright", ["Author 1", "Author 2", "etc."], "Comments";
$about->signal_connect(destroy => sub {exit});

show $about;

main Gtk;
