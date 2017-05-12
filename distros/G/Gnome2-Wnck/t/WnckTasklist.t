#!/usr/bin/perl -w
use strict;
use Test::More;
use Gnome2::Wnck;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/t/WnckTasklist.t,v 1.11 2007/08/02 20:15:43 kaffeetisch Exp $

unless (Gtk2 -> init_check()) {
  plan skip_all => "Couldn't initialize Gtk2";
}
else {
  Gtk2 -> init();
  plan tests => 2;
}

###############################################################################

my $screen = Gnome2::Wnck::Screen -> get_default();
$screen -> force_update();

###############################################################################

my $tasklist = Gnome2::Wnck::Tasklist -> new($screen);

$tasklist -> set_screen($screen);

$tasklist -> set_icon_loader(sub {
  my ($icon_name, $size, $flags, $data) = @_;

  warn join(", ", ($icon_name, $size, $flags, $data));
  warn join(", ", $tasklist -> get_size_hint_list());

  return Gtk2::Gdk::Pixbuf -> new();
}, "bla");

$tasklist -> set_grouping("auto-group");
$tasklist -> set_switch_workspace_on_unminimize(1);
$tasklist -> set_grouping_limit(5);
$tasklist -> set_include_all_workspaces(0);

$tasklist -> set_minimum_width(50);
ok(defined $tasklist -> get_minimum_width());

$tasklist -> set_minimum_height(20);
ok(defined $tasklist -> get_minimum_height());

$tasklist -> set_button_relief("normal");
