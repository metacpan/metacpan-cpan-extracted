#!/usr/bin/env perl
use Gtk2::TestHelper
  tests => 6,
  noinit => 1,
  at_least_version => [2, 14, 0, "Gtk2::HSV is new in 2.14"];

my $hsv = Gtk2::HSV->new;
isa_ok ($hsv, 'Gtk2::HSV');

$hsv->set_color (0, 0, 0);
is_deeply ([$hsv->get_color], [0, 0, 0]);

$hsv->set_metrics (23, 1);
is_deeply ([$hsv->get_metrics], [23, 1]);

ok (!$hsv->is_adjusting);

is_deeply ([Gtk2::hsv_to_rgb (0, 0, 0)], [0, 0, 0]);
is_deeply ([Gtk2::rgb_to_hsv (0, 0, 0)], [0, 0, 0]);

__END__

Copyright (C) 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
