#!/usr/bin/perl

#TITLE: Gnome Zvt
#REQUIRES: Gtk Gnome

BEGIN {$Gtk::lazy++}

use Gnome;
init Gnome "perl-zterm.pl";

$NAME = 'Perl-ZTerm';

$w = new Gtk::Window -toplevel;

$w->set_title("Perl-ZTerm");
$w->set_policy(0, 1, 1);
$w->signal_connect( destroy => sub {exit} );

$table = new Gtk::Table 1, 2, 0;

$term = new Gnome::ZvtTerm;

$term->signal_connect(child_died => sub { exit });
$term->set_scrollback(50);
$term->set_font_name("-misc-fixed-medium-r-normal--20-200-75-75-c-100-iso8859-1");

$scrollbar = new Gtk::VScrollbar $term->adjustment;
$scrollbar->can_focus(0);

$w->add($table);
$table->attach($scrollbar, 0,1, 0,1, -fill, [-expand, -shrink, -fill], 0, 0);
$table->attach($term, 1,2, 0,1, [-expand, -shrink, -fill], [-expand, -shrink, -fill], 0, 0);

show $term;
show $scrollbar;
show $table;
show $w;

if ($term->forkpty(0) == 0) {
	exec "/bin/bash";
	kill "KILL", $$;
}

$term->writechild("ls\n");

main Gtk;
