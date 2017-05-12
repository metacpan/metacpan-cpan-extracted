#!/usr/bin/perl -w
use strict;
use Gtk2::TestHelper tests => 23;


{
  my $visual = Gtk2::Gdk::Visual->get_system;
  my $image = Gtk2::Gdk::Image->new ('normal', $visual, 7, 8);

  is ($image->get_image_type, 'normal', "get_image_type()");
  is ($image->get_visual, $visual, "get_visual()");
  ok ($image->get_byte_order, "get_byte_order()");
  is ($image->get_width,  7, "get_width()");
  is ($image->get_height, 8, "get_height()");
  is ($image->get_depth, $visual->depth, "get_depth()");
  cmp_ok ($image->get_bytes_per_pixel, '>', 0, "get_bytes_per_pixel()");
  cmp_ok ($image->get_bytes_per_line,  '>', 0, "get_bytes_per_line()");
  cmp_ok ($image->get_bytes_per_line, '>=', $image->get_bytes_per_pixel,
	  "bytes_per_line >= bytes_per_pixel");
  cmp_ok ($image->get_bits_per_pixel,  '>', 0, "bits_per_pixel");
  cmp_ok (8 * $image->get_bytes_per_pixel, '>=', $image->get_bits_per_pixel,
	  "8 * bytes_per_pixel >= bits_per_pixel");

  is ($image->get_colormap, undef, "no initial colormap");
  my $new_colormap = Gtk2::Gdk::Colormap->new ($visual, 1);
  $image->set_colormap ($new_colormap);
  is ($image->get_colormap, $new_colormap, "get_colormap");

  my $mem = $image->get_pixels;
  is (length($mem), $image->get_bytes_per_line * $image->get_height,
      "get_pixels() length");
}

{
  require Scalar::Util;
  my $visual = Gtk2::Gdk::Visual->get_system;
  my $image = Gtk2::Gdk::Image->new ('normal', $visual, 10, 10);
  Scalar::Util::weaken ($image);
  is ($image, undef, 'image destroyed on weaken');
}

{
  my $visual = Gtk2::Gdk::Visual->get_system;
  my $image = Gtk2::Gdk::Image->new ('normal', $visual, 10, 10);
  my $colormap1 = Gtk2::Gdk::Colormap->new ($visual, 1);
  my $colormap2 = Gtk2::Gdk::Colormap->new ($visual, 1);

  $image->set_colormap ($colormap1);
  is ($image->get_colormap, $colormap1, "get_colormap");
  $image->set_colormap ($colormap2);
  is ($image->get_colormap, $colormap2, "get_colormap");

  Scalar::Util::weaken ($image);
  is ($image, undef, 'image destroyed on weaken');

  Scalar::Util::weaken ($colormap1);
  is ($image, undef,
      "colormap1 destroyed on weaken (image doesn't hang onto it)");

  Scalar::Util::weaken ($colormap2);
  is ($image, undef,
      "colormap2 destroyed on weaken (image doesn't hang onto it)");
}

{
  my $visual = Gtk2::Gdk::Visual->get_system;
  my $image = Gtk2::Gdk::Image->new ('normal', $visual, 10, 10);

  # pixel values 0 and 1 are always available, even on a depth==1 monochrome
  # visual
  $image->put_pixel (5,6, 0);
  is ($image->get_pixel(5,6), 0, "get_pixel");
  $image->put_pixel (5,6, 1);
  is ($image->get_pixel(5,6), 1, "get_pixel");
  $image->put_pixel (5,6, 0);
  is ($image->get_pixel(5,6), 0, "get_pixel");
}

__END__

Copyright (C) 2010 by the gtk2-perl team (see the file AUTHORS for the
full list).  See LICENSE for more information.
