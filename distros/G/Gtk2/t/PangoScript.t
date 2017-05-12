#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 8;

# $Id$

SKIP: {
  skip("PangoScript is new in 1.4", 8)
    unless (Gtk2::Pango -> CHECK_VERSION(1, 4, 0));

  is(Gtk2::Pango::Script -> for_unichar("a"), "latin");

  my $lang = Gtk2::Pango::Script -> get_sample_language("latin");
  isa_ok($lang, "Gtk2::Pango::Language");
  is($lang -> includes_script("latin"), 1);

  my $iter = Gtk2::Pango::ScriptIter -> new("urgs");
  isa_ok($iter, "Gtk2::Pango::ScriptIter");

  my ($start, $end, $script) = $iter -> get_range();
  is($start, "urgs");
  is($end, "");
  is($script, "latin");

  ok(!$iter -> next());
}

__END__

Copyright (C) 2004 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
