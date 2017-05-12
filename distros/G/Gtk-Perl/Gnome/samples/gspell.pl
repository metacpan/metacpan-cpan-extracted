#!/usr/bin/perl -w

#TITLE: Spell Checker
#REQUIRES: Gnome

use Gnome;

Gnome->init("spell-check");

$w = new Gnome::Dialog("spell-check", "Quit");
$sp = new Gnome::Spell;
$sp->signal_connect('found_word', sub {
	my ($s, $i) = @_;
	print "FOUND WORD: $i->{word}\n";
	print "ALTERNATIVES: ", join(" ", @{$i->{words}}), "\n" if defined $i->{words};
});

$w->vbox->add($sp);
$l = new Gtk::Label ("Insert here the words to spell-check and press ENTER:");
$w->vbox->add($l);
$e = new Gtk::Entry;
$w->vbox->add($e);

$e->signal_connect('activate', sub {$sp->check(shift->get_text)});
$w->signal_connect('clicked', sub {Gtk->main_quit;});
$w->show_all;

Gtk->main;
