#!/usr/bin/perl
use Gtk2 -init;
use Gtk2::TrayIcon;
use strict;

my $icon = Gtk2::TrayIcon->new('foo');

$icon->add(Gtk2::Image->new_from_stock('gtk-dialog-warning', 'menu'));

$icon->show_all;

Glib::Timeout->add(5000, sub {
	print "sending message\n";
	$icon->send_message(5000, "hello, world!");
});

Gtk2->main;
