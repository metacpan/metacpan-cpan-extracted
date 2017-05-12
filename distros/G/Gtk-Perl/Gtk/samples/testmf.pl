#!/usr/bin/perl -w

#TITLE: MenuFactory
#REQUIRES: Gtk

use Gtk;

init Gtk;

$factory = new Gtk::MenuFactory('menu_bar');
$subfactory = new Gtk::MenuFactory('menu_bar');
$factory->add_subfactory($subfactory, '<Main>');
$entry1 = { path  =>  '<Main>/File/Hello',
           accelerator     =>  '<alt>H',
           widget          =>  undef,
           callback        =>  sub {print "Hello world!\n"}
         };
$entry2 = { path  =>  '<Main>/File/Quit',
           accelerator     =>  '<alt>Q',
           widget          =>  undef,
           callback        =>  sub {Gtk->exit(0)}
         };
    $factory->add_entries($entry1, $entry2);
    $menubar = $subfactory->widget;

#$entry->{'widget'}->show;
$menubar->show;
$win = new Gtk::Window;
$win->add($menubar);
$win->show;
$win->signal_connect('delete_event', sub {Gtk->exit(0)});
main Gtk;

