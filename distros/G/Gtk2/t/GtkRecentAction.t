#!/usr/bin/perl

# $Id$

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
	at_least_version => [2, 12, 0, 'GtkRecentAction: new in 2.12'],
	tests => 1,
	(on_unthreaded_freebsd () ? (skip_all => 'need a perl compiled with "-pthread" on freebsd') : ());

my $action = Gtk2::RecentAction->new (name => 'one',
                                      label => 'one',
                                      tooltip => 'one',
                                      stock_id => 'gtk-ok',
                                      recent_manager => Gtk2::RecentManager->new);
isa_ok($action, 'Gtk2::RecentAction');

__END__

Copyright (C) 2007 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
