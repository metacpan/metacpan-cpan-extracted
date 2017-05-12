#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 32;

# $Id$

my @depths = Gtk2::Gdk -> query_depths();
like($depths[0], qr/^\d+$/);

my @types = Gtk2::Gdk -> query_visual_types();
ok(defined($types[0]));

my @visuals = Gtk2::Gdk -> list_visuals();
isa_ok($visuals[0], "Gtk2::Gdk::Visual");

like(Gtk2::Gdk::Visual -> get_best_depth(), qr/^\d+$/);
ok(defined(Gtk2::Gdk::Visual -> get_best_type()));

isa_ok(my $visual = Gtk2::Gdk::Visual -> get_system(), "Gtk2::Gdk::Visual");
isa_ok(Gtk2::Gdk::Visual -> get_best(), "Gtk2::Gdk::Visual");
isa_ok(Gtk2::Gdk::Visual -> get_best_with_type($types[0]), "Gtk2::Gdk::Visual");
SKIP: {
  my $best = Gtk2::Gdk::Visual -> get_best_with_both($depths[0], $types[0]);
  skip 'best test', 1 unless defined $best;
  isa_ok($best, "Gtk2::Gdk::Visual");
}

SKIP: {
  skip("get_best_with_depth seems to be broken in 2.2", 1)
    if ((Gtk2 -> GET_VERSION_INFO())[0] == 2 &&
        (Gtk2 -> GET_VERSION_INFO())[1] == 2);

  isa_ok(Gtk2::Gdk::Visual -> get_best_with_depth($depths[0]), "Gtk2::Gdk::Visual");
}

SKIP: {
  skip("GdkScreen is new in 2.2", 1)
    unless (Gtk2 -> CHECK_VERSION(2, 2, 0));

  isa_ok($visual -> get_screen(), "Gtk2::Gdk::Screen");
}

ok(defined($visual -> type));
ok(defined($visual -> byte_order));
like($visual -> colormap_size, qr/^\d+$/);
like($visual -> bits_per_rgb, qr/^\d+$/);
like($visual -> red_mask, qr/^\d+$/);
like($visual -> red_shift, qr/^\d+$/);
like($visual -> red_prec, qr/^\d+$/);
like($visual -> green_mask, qr/^\d+$/);
like($visual -> green_shift, qr/^\d+$/);
like($visual -> green_prec, qr/^\d+$/);
like($visual -> blue_mask, qr/^\d+$/);
like($visual -> blue_shift, qr/^\d+$/);
like($visual -> blue_prec, qr/^\d+$/);

SKIP: {
  skip 'new 2.22 stuff', 8
    unless Gtk2->CHECK_VERSION(2, 22, 0);

  my $visual = Gtk2::Gdk::Visual -> get_system();

  my ($mask, $shift, $precision) = $visual -> get_blue_pixel_details();
  ok(defined $mask && defined $shift && defined $precision);
  ($mask, $shift, $precision) = $visual -> get_green_pixel_details();
  ok(defined $mask && defined $shift && defined $precision);
  ($mask, $shift, $precision) = $visual -> get_red_pixel_details();
  ok(defined $mask && defined $shift && defined $precision);

  ok(defined $visual -> get_bits_per_rgb());
  ok(defined $visual -> get_byte_order());
  ok(defined $visual -> get_colormap_size());
  ok(defined $visual -> get_depth());
  ok(defined $visual -> get_visual_type());
}

__END__

Copyright (C) 2004 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
