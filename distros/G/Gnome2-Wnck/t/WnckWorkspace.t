#!/usr/bin/perl -w
use strict;
use Test::More;
use Gnome2::Wnck;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/t/WnckWorkspace.t,v 1.12 2007/08/02 20:15:43 kaffeetisch Exp $

unless (Gtk2 -> init_check()) {
  plan skip_all => "Couldn't initialize Gtk2";
}
else {
  Gtk2 -> init();
  plan tests => 10;
}

###############################################################################

my $screen = Gnome2::Wnck::Screen -> get_default();
$screen -> force_update();

###############################################################################

my $workspace = $screen -> get_workspace(0);

SKIP: {
  skip("couldn't get first workspace", 10) unless (defined($workspace));

  is($workspace -> get_number(), 0);
  ok(defined($workspace -> get_name()));

  like($workspace -> get_width(), qr/^\d+$/);
  like($workspace -> get_height(), qr/^\d+$/);
  like($workspace -> get_viewport_x(), qr/^\d+$/);
  like($workspace -> get_viewport_y(), qr/^\d+$/);
  ok(not $workspace -> is_virtual());

  $screen -> get_active_workspace() -> activate(time());

  isa_ok($workspace -> get_screen(), 'Gnome2::Wnck::Screen');
  ok(defined $workspace -> get_layout_row());
  ok(defined $workspace -> get_layout_column());
  $workspace -> get_neighbor('right'); # might be undef

  # $workspace -> change_name(...);
}
