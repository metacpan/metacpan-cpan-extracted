#!/usr/bin/perl
use warnings;
use strict;

# Liberally taken from http://poe.perl.org/?POE_Cookbook/Gtk2_Counter

use Gtk3-init;
use IO::Lambda qw(:lambda);
use IO::Lambda::Loop::Glib;

my $window = Gtk3::Window->new("toplevel");
$window->signal_connect(destroy => sub { Gtk3->main_quit });
my $box = Gtk3::VBox->new(0, 0);
$window->add($box);
my $label = Gtk3::Label->new("Counter");
$box->pack_start($label, 1, 1, 0);
my $counter = 0;
my $counter_label = Gtk3::Label->new($counter);
$box->pack_start($counter_label, 1, 1, 0);
my $button = Gtk3::Button->new("Clear");
$button->signal_connect("clicked", sub { $counter_label->set_text($counter = 0) });
$box->pack_start($button, 1, 1, 0);
$window->show_all();

my $l = lambda {
	context 1;
	timeout {
		$counter_label->set_text(++$counter);
		again;
	};
};
$l->start;

Gtk3->main;
