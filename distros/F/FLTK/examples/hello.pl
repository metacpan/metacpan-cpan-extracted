#!/usr/bin/perl
# The ubiquitous Hello World in 6 lines of Perl using the perl FLTK module.

use FLTK qw( :Boxtypes );

$win = new Fl_Window(110, 40, "$0");
$btn = new Fl_Highlight_Button(5,5,100,30, "Hello World!");
$btn->callback(\&fancy_cb, 'foo');
$btn->box(FL_THIN_UP_BOX);
$win->end();

$win->show();
Fl::run();

sub fancy_cb {
  my ($w, $data) = @_;
  print "I'm a callback.\nI was called by a widget with the label ";
  print $w->label();
  print "\nI was passed a data argument containing '$data'.\n";
  print "Buh bye now.\n";
  exit;
}
