#!/usr/bin/perl -w
use strict;
use Gnome2;

use constant TESTS => 17;
use Test::More tests => TESTS;

# $Id$

###############################################################################

SKIP: {
  our $application;
  do "t/TestBoilerplate";

  #############################################################################

  my ($druid,
      $druid_window) = Gnome2::Druid -> new_with_window("Bleh", undef, 1);
  isa_ok($druid, "Gnome2::Druid");
  isa_ok($druid_window, "Gtk2::Window");

  $druid = Gnome2::Druid -> new();
  isa_ok($druid, "Gnome2::Druid");

  $druid -> set_buttons_sensitive(1, 1, 1, 1);
  $druid -> set_show_finish(0);
  $druid -> set_show_help(1);

  #############################################################################

  my $dummy = Gnome2::DruidPage -> new();

  foreach (qw(back cancel finish prepare next)) {
    $dummy -> signal_connect($_ => sub { ok(1); return 1; });
  }

  $dummy -> back();
  $dummy -> cancel();
  $dummy -> finish();
  $dummy -> prepare();
  $dummy -> next();

  #############################################################################

  my $first = Gnome2::DruidPageEdge -> new_aa("start");
  isa_ok($first, "Gnome2::DruidPageEdge");

  $first = Gnome2::DruidPageEdge -> new_with_vals("start", 1, "Blub", "Bla Blub");
  isa_ok($first, "Gnome2::DruidPageEdge");

  $first = Gnome2::DruidPageEdge -> new("start");
  isa_ok($first, "Gnome2::DruidPageEdge");

  $first -> set_bg_color(Gtk2::Gdk::Color -> new(0, 255, 0));
  $first -> set_textbox_color(Gtk2::Gdk::Color -> new(255, 0, 0));
  $first -> set_logo_bg_color(Gtk2::Gdk::Color -> new(0, 0, 255));
  $first -> set_title_color(Gtk2::Gdk::Color -> new(255, 255, 0));
  $first -> set_text_color(Gtk2::Gdk::Color -> new(0, 255, 255));

  $first -> set_text("Schmih");
  $first -> set_title("Schmuh");

  $first -> set_logo(undef);
  $first -> set_watermark(undef);
  $first -> set_top_watermark(undef);

  #############################################################################

  my $middle = Gnome2::DruidPageStandard -> new_with_vals("Blub");
  isa_ok($middle, "Gnome2::DruidPageStandard");
  isa_ok($middle -> vbox(), "Gtk2::VBox");

  $middle = Gnome2::DruidPageStandard -> new();
  isa_ok($middle, "Gnome2::DruidPageStandard");

  $middle -> set_background(Gtk2::Gdk::Color -> new(0, 255, 0));
  $middle -> set_logo_background(Gtk2::Gdk::Color -> new(0, 0, 255));
  $middle -> set_title_foreground(Gtk2::Gdk::Color -> new(255, 255, 0));

  SKIP: {
    skip("set_contents_background was broken prior to 2.8", 0)
      unless (Gnome2 -> CHECK_VERSION(2, 8, 0));

    $middle -> set_contents_background(Gtk2::Gdk::Color -> new(255, 255, 0));
  }

  $middle -> set_title("Schmuh");

  $middle -> set_logo(undef);
  $middle -> set_top_watermark(undef);

  $middle -> append_item("What?", Gtk2::Label -> new("Hrmpf!"), "Really!");

  #############################################################################

  my $last = Gnome2::DruidPageEdge -> new_aa("finish");
  isa_ok($last, "Gnome2::DruidPageEdge");

  $last = Gnome2::DruidPageEdge -> new_with_vals("finish", 1, "Blub", "Bla Blub");
  isa_ok($last, "Gnome2::DruidPageEdge");

  $last = Gnome2::DruidPageEdge -> new("start");
  isa_ok($last, "Gnome2::DruidPageEdge");

  $last -> set_bg_color(Gtk2::Gdk::Color -> new(0, 255, 0));
  $last -> set_textbox_color(Gtk2::Gdk::Color -> new(255, 0, 0));
  $last -> set_logo_bg_color(Gtk2::Gdk::Color -> new(0, 0, 255));
  $last -> set_title_color(Gtk2::Gdk::Color -> new(255, 255, 0));
  $last -> set_text_color(Gtk2::Gdk::Color -> new(0, 255, 255));

  $last -> set_text("Schmih");
  $last -> set_title("Schmuh");

  $last -> set_logo(undef);
  $last -> set_watermark(undef);
  $last -> set_top_watermark(undef);

  #############################################################################

  $druid -> prepend_page($first);
  $druid -> insert_page($first, $middle);
  $druid -> append_page($last);

  $druid -> set_page($middle);
}
