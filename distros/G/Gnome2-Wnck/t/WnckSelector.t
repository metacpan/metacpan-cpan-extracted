#!/usr/bin/perl -w
use strict;
use Test::More;
use Gnome2::Wnck;

# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-Wnck/t/WnckSelector.t,v 1.2 2007/08/02 20:15:43 kaffeetisch Exp $

unless (Gnome2::Wnck -> CHECK_VERSION(2, 10, 0)) {
  plan skip_all => "WnckSelector is new in 2.10";
}

unless (Gtk2 -> init_check()) {
  plan skip_all => "Couldn't initialize Gtk2";
}
else {
  Gtk2 -> init();
  plan tests => 1;
}

###############################################################################

my $selector = Gnome2::Wnck::Selector -> new();
isa_ok($selector, "Gtk2::Widget");
