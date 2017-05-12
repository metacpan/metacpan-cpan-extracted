#!/usr/bin/perl
use Gtk2 -init;
use Gtk2::TrayManager;
use Data::Dumper;
use strict;

my $screen = Gtk2::Gdk::Screen->get_default;

if (Gtk2::TrayManager->check_running($screen)) {
	print STDERR "A tray manager is already running, sorry!\n";
	exit 256;
}

my $window = Gtk2::Window->new;
$window->add(Gtk2::VBox->new);
$window->set_resizable(0);

my $tray = Gtk2::TrayManager->new;
$tray->manage_screen($screen);
$tray->set_orientation('vertical');

$tray->signal_connect('tray_icon_added', sub {
	$window->child->add($_[1]);
	$_[1]->show_all;
});

$tray->signal_connect('tray_icon_removed', sub {
	$window->child->remove($_[1]);
});

$tray->signal_connect('message_sent', sub { print "message_sent\n" . Dumper(\@_) });
$tray->signal_connect('message_cancelled', sub { print "message_cancelled\n" . Dumper(\@_) });
$tray->signal_connect('lost_selection', sub { print "lost_selection\n" . Dumper(\@_) });

$window->show_all;

Gtk2->main;
