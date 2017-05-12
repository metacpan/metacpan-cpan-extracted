#!/usr/bin/perl -w

# TITLE: MDI
# REQUIRES: Gnome

use Gnome;

init Gnome 'test';

$mdi = new Gnome::MDI('test', "Perl MDI example");
$mdi->set_mode('notebook');

$mdichild = new Gnome::MDIGenericChild 'test';
$mdichild->set_view_creator(sub {return new Gtk::Button('test child')});

$mdichild2 = new Gnome::MDIGenericChild 'test2';
$mdichild2->set_view_creator(sub {return new Gtk::Button('test child2')});

$mdi->add_view($mdichild);
$mdi->add_view($mdichild2);

$mdi->open_toplevel;

main Gtk;

