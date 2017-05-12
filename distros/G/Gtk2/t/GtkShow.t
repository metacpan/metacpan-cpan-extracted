#!/usr/bin/perl
use strict;
use warnings;
use Gtk2::TestHelper
  tests => 1,
  at_least_version => [2, 14, 0, 'GtkShow is new in 2.14'],
  skip_all => 'can only test interactively',
  ;

# $Id$

eval {
  Gtk2::show_uri(undef, 'http://www.gnome.org');
  Gtk2::show_uri(undef, 'http://www.gtk.org', time());

  my $screen = Gtk2::Gdk::Screen -> get_default();
  Gtk2::show_uri($screen, 'http://gtk2-perl.sf.net');
};

is ($@, '');

__END__

Copyright (C) 2008 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
