#!/usr/bin/perl -w
use strict;
use Test::More;
use Gnome2::Wnck;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/t/WnckScreen.t,v 1.11 2007/08/02 20:15:43 kaffeetisch Exp $

unless (Gtk2 -> init_check()) {
  plan skip_all => "Couldn't initialize Gtk2";
}
else {
  Gtk2 -> init();
  plan tests => 16;
}

###############################################################################

my $screen = Gnome2::Wnck::Screen -> get(0);
isa_ok($screen, "Gnome2::Wnck::Screen");

# get_for_root()

$screen = Gnome2::Wnck::Screen -> get_default();
isa_ok($screen, "Gnome2::Wnck::Screen");

$screen -> force_update();

SKIP: {
  my $workspace = $screen -> get_workspace(0);
  skip("couldn't get first workspace", 1) unless (defined($workspace));
  isa_ok($workspace, "Gnome2::Wnck::Workspace");
}

SKIP: {
  my $workspace = $screen -> get_active_workspace();
  skip("couldn't get active workspace", 1) unless (defined($workspace));
  isa_ok($workspace, "Gnome2::Wnck::Workspace");
}

SKIP: {
  my $active_window = $screen -> get_active_window();
  skip("no active window found", 1) unless (defined($active_window));
  isa_ok($active_window, "Gnome2::Wnck::Window");
}

SKIP: {
  my $prev_window = $screen -> get_previously_active_window();
  skip("no previously active window found", 1) unless (defined($prev_window));
  isa_ok($prev_window, "Gnome2::Wnck::Window");
}

SKIP: {
  my @windows = $screen -> get_windows();
  skip("couldn't get windows", 1) unless (@windows);
  isa_ok($windows[0], "Gnome2::Wnck::Window");
}

SKIP: {
  my @windows = $screen -> get_windows_stacked();
  skip("couldn't get stacked windows", 1) unless (@windows);
  isa_ok($windows[0], "Gnome2::Wnck::Window");
}

SKIP: {
  like($screen -> get_workspace_count(), qr/^\d+$/);
  like($screen -> get_showing_desktop(), qr/^(?:1|)$/);
  # $screen -> toggle_showing_desktop(1);
}

like($screen -> get_background_pixmap(), qr/^\d+$/);
like($screen -> get_width(), qr/^\d+$/);
like($screen -> get_height(), qr/^\d+$/);
like($screen -> net_wm_supports("_NET_WM_PID"), qr/^(?:1|)$/);

# $screen -> change_workspace_count(10);
# $screen -> move_viewport(23, 42);
# $screen -> try_set_workspace_layout(...);
# $screen -> release_workspace_layout(...);

my @workspaces = $screen -> get_workspaces();
isa_ok($workspaces[0], 'Gnome2::Wnck::Workspace');

$screen -> get_window_manager_name(); # might be undef

ok(defined $screen -> get_number());
