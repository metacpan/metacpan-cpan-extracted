#!/usr/bin/perl

use Gnome;

init Gnome "gnome-dns.pl";

init Gnome::DNS;

$NAME = "DNS Lookup";

$w = new Gtk::Window -toplevel;
show $w;

$b = new Gtk::Button "Lookup";
$w->add($b);
show $b;

$b->signal_connect(clicked => sub {

	print "Starting DNS lookup...\n";

	Gnome::DNS->lookup("www.gnome.org",
		sub {
			my $o = Gnome::DialogUtil->ok("Address of www.gnome.org is $_[1], data is $_[0]");
			$o->signal_connect("destroy", sub {Gtk->main_quit});
		}, 34);
});

main Gtk;
