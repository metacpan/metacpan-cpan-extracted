#!/usr/bin/perl

use Gtk;

$NAME = 'Button';

init Gtk;

$w = new Gtk::Window -toplevel;

$w->signal_connect( destroy => sub {exit} );

show $w;

$b = new Gtk::Button 'Button';
$w->add($b);
show $b;

main Gtk;
