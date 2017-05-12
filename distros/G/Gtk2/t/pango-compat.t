#!/usr/bin/perl
use strict;
use warnings;
use Gtk2::TestHelper tests => 3;

# Make sure that the old names for object, boxed, and fundamental types work.
# Pango 1.0 didn't have an interface type, so we can't test one without
# fiddling with version checks.
is (eval {
  Gtk2::TreeStore->new (qw/Gtk2::Pango::Layout
                           Gtk2::Pango::Color
                           Gtk2::Pango::Weight
                           Gtk2::Pango::FontMask/);
  1;
}, 1);

# Make sure that objects of some type also appear to be of the old type
my $label = Gtk2::Label->new ();
my $layout = $label->get_layout ();
isa_ok ($layout, qw/Gtk2::Pango::Layout/);
isa_ok ($layout, qw/Pango::Layout/);

__END__

Copyright (C) 2008 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
