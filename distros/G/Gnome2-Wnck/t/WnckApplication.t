#!/usr/bin/perl -w
use strict;
use Test::More;
use Gnome2::Wnck;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/t/WnckApplication.t,v 1.7 2004/08/10 18:17:13 kaffeetisch Exp $

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

SKIP: {
  my $window = $screen -> get_active_window();
  skip("no active window found", 10) unless (defined($window));

  my $application = $window -> get_application();

  isa_ok($application -> get_icon(), "Gtk2::Gdk::Pixbuf");
  isa_ok($application -> get_mini_icon(), "Gtk2::Gdk::Pixbuf");

  like($application -> get_xid(), qr/^\d+$/);
  is(Gnome2::Wnck::Application -> get($application -> get_xid()), $application);
  like($application -> get_pid(), qr/^\d+$/);
  like($application -> get_n_windows(), qr/^\d+$/);
  ok($application -> get_name());
  ok($application -> get_icon_name());

  isa_ok(($application -> get_windows())[0], "Gnome2::Wnck::Window");

  like($application -> get_icon_is_fallback(), qr/^(?:1|)$/);
  # $application -> get_startup_id();
}
