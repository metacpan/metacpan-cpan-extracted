#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 9, noinit => 1;

# $Id$

SKIP: {
  skip("find_base_dir is new in 1.4", 1)
    unless (Gtk2::Pango -> CHECK_VERSION(1, 4, 0));

  is(Gtk2::Pango -> find_base_dir("urgs"), "ltr");
}

my $language = Gtk2::Pango::Language -> from_string("de_DE");
isa_ok($language, "Gtk2::Pango::Language");
is($language -> to_string(), "de-de");
is($language -> matches("*"), 1);

SKIP: {
  skip "1.16 stuff", 5
    unless Gtk2::Pango -> CHECK_VERSION(1, 16, 0);

  isa_ok(Gtk2::Pango::Language -> get_default(), "Gtk2::Pango::Language");

  is(Gtk2::Pango::units_from_double(Gtk2::Pango::units_to_double(23)), 23);

  my $rect = {x => 1.0, y => 2.0, width => 23.0, height => 42.0};
  my ($new_ink, $new_logical) = Gtk2::Pango::extents_to_pixels($rect, $rect);
  isa_ok($new_ink, "HASH");
  isa_ok($new_logical, "HASH");

  is_deeply([Gtk2::Pango::extents_to_pixels(undef, undef)], [undef, undef]);
}

__END__

Copyright (C) 2004-2007 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
