#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 13;

# $Id$

use Glib qw(TRUE FALSE);
use Gtk2::SourceView;

my $view = Gtk2::SourceView::View -> new();
isa_ok($view, "Gtk2::SourceView::View");

my $table = Gtk2::SourceView::TagTable -> new();
my $buffer = Gtk2::SourceView::Buffer -> new($table);

$view = Gtk2::SourceView::View -> new_with_buffer($buffer);
isa_ok($view, "Gtk2::SourceView::View");

$view -> set_show_line_numbers(TRUE);
is($view -> get_show_line_numbers(), TRUE);

$view -> set_show_line_markers(TRUE);
is($view -> get_show_line_markers(), TRUE);

$view -> set_tabs_width(8);
is($view -> get_tabs_width(), 8);

$view -> set_auto_indent(TRUE);
is($view -> get_auto_indent(), TRUE);

$view -> set_insert_spaces_instead_of_tabs(TRUE);
is($view -> get_insert_spaces_instead_of_tabs(), TRUE);

$view -> set_show_margin(TRUE);
is($view -> get_show_margin(), TRUE);

SKIP: {
  skip "new stuff", 1
    unless Gtk2::SourceView -> CHECK_VERSION(1, 2, 0);

  $view -> set_highlight_current_line(TRUE);
  is($view -> get_highlight_current_line(), TRUE);
}

$view -> set_margin(23);
is($view -> get_margin(), 23);

my $pixbuf = Gtk2::Gdk::Pixbuf -> new("rgb", FALSE, 8, 10, 10);

$view -> set_marker_pixbuf("left", $pixbuf);
is($view -> get_marker_pixbuf("left"), $pixbuf);

$view -> set_marker_pixbuf("left", undef);
is($view -> get_marker_pixbuf("left"), undef);

$view -> set_smart_home_end(TRUE);
is($view -> get_smart_home_end(), TRUE);
