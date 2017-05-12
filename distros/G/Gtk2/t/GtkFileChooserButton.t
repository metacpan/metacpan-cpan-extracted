#!/usr/bin/perl -w
use strict;

sub on_unthreaded_freebsd {
  if ($^O eq 'freebsd') {
    require Config;
    if ($Config::Config{ldflags} !~ m/-pthread\b/) {
      return 1;
    }
  }
  return 0;
}

use Gtk2::TestHelper
  tests => 9,
  at_least_version => [2, 6, 0, "GtkFileChooserButton is new in 2.6"],
  (on_unthreaded_freebsd () ? (skip_all => 'need a perl compiled with "-pthread" on freebsd') : ());

# $Id$

my $dialog = Gtk2::FileChooserDialog -> new("Urgs", undef, "open",
                                            "gtk-cancel" => "cancel",
                                            "gtk-ok" => "ok");

my $button = Gtk2::FileChooserButton -> new("Urgs", "open");
isa_ok($button, "Gtk2::FileChooserButton");
ginterfaces_ok($button);

$button = Gtk2::FileChooserButton -> new_with_backend("Urgs", "open", "backend");
isa_ok($button, "Gtk2::FileChooserButton");
isa_ok($button, "Gtk2::FileChooser");

$button = Gtk2::FileChooserButton -> new_with_dialog($dialog);
isa_ok($button, "Gtk2::FileChooserButton");
isa_ok($button, "Gtk2::FileChooser");

$button -> set_title("Urgs");
is($button -> get_title(), "Urgs");

$button -> set_width_chars(23);
is($button -> get_width_chars(), 23);

SKIP: {
  skip "new 2.10 stuff", 1
    unless Gtk2 -> CHECK_VERSION(2, 10, 0);

  $button -> set_focus_on_click(TRUE);
  is($button -> get_focus_on_click(), TRUE);
}

__END__

Copyright (C) 2004-2006 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
