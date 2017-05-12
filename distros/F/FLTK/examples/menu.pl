#!/usr/bin/perl
use FLTK;

$win = new Fl_Window(300, 200, "$0");
$mb = new Fl_Menu_Bar(0,0,300,25);
$mb->begin();
$fm = new Fl_Item_Group('&File');
$item = new Fl_Item("Quit");
$item->callback(sub { exit;});
$fm->end();
$mb->end();
$win->end();

$win->show();
Fl::run();
