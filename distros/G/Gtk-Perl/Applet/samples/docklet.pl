#!/usr/bin/perl -w
# REQUIRES: Gnome Applet
# TITLE: docklet

use Gnome::Applet;

init Gnome::AppletWidget 'docklet';

my $d = new Gnome::StatusDocklet;
$d->signal_connect("build_plug", sub {
	my ($docklet, $plug) = @_;
	my $l = new Gtk::Label("hey!");
	$l->show;
	$plug->add($l);
});

$d->run;

Gnome::AppletWidget->gtk_main;

