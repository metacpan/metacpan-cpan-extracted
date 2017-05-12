#!/usr/bin/perl -w

#TITLE: init/quit callbacks
#REQUIRES: Gtk
use strict;
use Gtk;

my $count = 0;
my $oscount = 0;

Gtk->init_add(sub {print STDERR "Init callback: ", @_, "\n"}, 1);

init Gtk;
#Gtk->quit_add(1, sub {print "Quit callback: ", @_, "\n"}, "burp");
Gtk->quit_add(1, \&quit_loop, "burp");
print STDERR "Quitting main loop in 1 sec\n";
Gtk->timeout_add(1000, \&main_quit);
Gtk->idle_add(sub {++$count; return 1});
Gtk->idle_add(sub {++$oscount; return 0});
Gtk->main;

print STDERR "Idle runs: $count\n";
print STDERR "One-shot idle runs: $oscount\n";

Gtk->exit(0);

sub quit_loop {
	print STDERR "Quit callback: ", @_,  "\n";
}

sub main_quit {
	Gtk->main_quit;
}
