#!/usr/bin/env perl
use Gtk2::TestHelper
  tests => 5,
  at_least_version => [2, 20, 0, "Gtk2::OffscreenWindow is new in 2.20"];

my $window = Gtk2::OffscreenWindow->new;
isa_ok ($window, 'Gtk2::OffscreenWindow');

$window->realize;

my $pixmap = $window->get_pixmap;
isa_ok ($pixmap, 'Gtk2::Gdk::Pixmap');
isa_ok ($pixmap->get_display, 'Gtk2::Gdk::Display');

my $pixbuf = $window->get_pixbuf;
isa_ok ($pixbuf, 'Gtk2::Gdk::Pixbuf');
ok (defined $pixbuf->get_colorspace);

__END__

Copyright (C) 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
