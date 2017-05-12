#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Test::More tests => 44;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::PixbufBits;

#----------------------------------------------------------------------------
{
  my $want_version = 48;
  is ($Gtk2::Ex::PixbufBits::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::PixbufBits->VERSION,  $want_version,
      'VERSION class method');
  ok (eval { Gtk2::Ex::PixbufBits->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::PixbufBits->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

# no init needed for pixbufs
require Gtk2;
MyTestHelpers::glib_gtk_versions();


#----------------------------------------------------------------------------
# type_max_size()

is_deeply ([Gtk2::Ex::PixbufBits::type_max_size('png')],
           [0x7FFFFFFF,0x7FFFFFFF]);
is_deeply ([Gtk2::Ex::PixbufBits::type_max_size('ico')],
           [0xFF,0xFF]);


#----------------------------------------------------------------------------
# type_supports_size()

ok (  Gtk2::Ex::PixbufBits::type_supports_size('png',0x7FFFFFFF,0x7FFFFFFF));
ok (! Gtk2::Ex::PixbufBits::type_supports_size('png',0x80000000,1));
ok (! Gtk2::Ex::PixbufBits::type_supports_size('png',0x80000000,1));
ok (! Gtk2::Ex::PixbufBits::type_supports_size('png',0xFFFFFFFF,0xFFFFFFFF));


#----------------------------------------------------------------------------
# save_adapt()

{
  my $pixbuf = Gtk2::Gdk::Pixbuf->new ('rgb',0,8,30,20);
  my $filename = 'test-filename.tmp';
  unlink $filename;
  ok (! -e $filename, "$filename removed");
  Gtk2::Ex::PixbufBits::save_adapt ($pixbuf, $filename, 'png');
  ok (-e $filename, "$filename saved");
  unlink $filename;
  ok (! -e $filename, "$filename removed again");
}

#----------------------------------------------------------------------------
# save_adapt_options()

{
  my $pixbuf = Gtk2::Gdk::Pixbuf->new ('rgb',0,8,30,20);
  my $filename = 'test-filename.tmp';

  foreach my $type ('png', 'tiff', 'jpeg', 'ico') {
    {
      my @ret = Gtk2::Ex::PixbufBits::save_adapt_options
        ($pixbuf, $filename, $type,
         'tEXt::Title' => 'Foo');
      is_deeply (\@ret,
                 [ $filename, $type,
                   ($type eq 'png' ? ('tEXt::Title' => 'Foo') : ()) ]);;
    }
    {
      my @ret = Gtk2::Ex::PixbufBits::save_adapt_options
        ($pixbuf, $filename, $type,
         x_hot => 1,
         y_hot => 2);
      is_deeply (\@ret,
                 [ $filename, $type,
                   ($type eq 'ico' ? (x_hot => 1, y_hot => 2) : ()) ]);;
    }

    {
      my @ret = Gtk2::Ex::PixbufBits::save_adapt_options
        ($pixbuf, $filename, $type,
         zlib_compression => 3);
      is_deeply (\@ret,
                 [ $filename, $type,
                   ($type eq 'png' && ! Gtk2->check_version(2,8,0)
                    ? (compression => 3) : ()) ]);;
    }
    {
      my @ret = Gtk2::Ex::PixbufBits::save_adapt_options
        ($pixbuf, $filename, $type,
         tiff_compression_type => 'lzw');
      is_deeply (\@ret,
                 [ $filename, $type,
                   ($type eq 'tiff' && ! Gtk2->check_version(2,20,0)
                    ? (compression => 5) : ()) ]);;
    }
    {
      my @ret = Gtk2::Ex::PixbufBits::save_adapt_options
        ($pixbuf, $filename, $type,
         tiff_compression_type => 1);
      is_deeply (\@ret,
                 [ $filename, $type,
                   ($type eq 'tiff' && ! Gtk2->check_version(2,20,0)
                    ? (compression => 1) : ()) ]);;
    }
    {
      my @ret = Gtk2::Ex::PixbufBits::save_adapt_options
        ($pixbuf, $filename, $type,
         quality_percent => 99);
      is_deeply (\@ret,
                 [ $filename, $type,
                   ($type eq 'jpeg' ? (quality => 99) : ()) ]);;
    }

  }
}

#----------------------------------------------------------------------------
# type_to_format()

SKIP: {
  Gtk2::Gdk::Pixbuf->can('get_formats')
      or skip 'Pixbuf get_formats() not available, per Gtk 2.0.x';

  ok (Gtk2::Ex::PixbufBits::type_to_format ('png'));
  {
    my @ret = Gtk2::Ex::PixbufBits::type_to_format
      ('Gtk2-Ex-PixbufBits-test-nosuchformatname');
    is_deeply (\@ret, [ undef ]);;
  }
}

#-----------------------------------------------------------------------------
# sampled_majority_color()

{
  my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_data
    ("\0\0\0",
     'rgb',
     0,    # alpha
     8,    # bits
     1,1,  # width,height
     3);   # rowstride
  is (Gtk2::Ex::PixbufBits::sampled_majority_color($pixbuf),
      '#000000',
      '1x1 black');
}
{
  my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_data
    ("\x00\x00\xFF",
     'rgb',
     0,    # alpha
     8,    # bits
     1,1,  # width,height
     3);   # rowstride
  is (Gtk2::Ex::PixbufBits::sampled_majority_color($pixbuf),
      '#0000FF',
      '1x1 blue');
}
{
  my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_data
    ("\x00\x00\xFF\x00",
     'rgb',
     1,    # alpha
     8,    # bits
     1,1,  # width,height
     4);   # rowstride
  is (Gtk2::Ex::PixbufBits::sampled_majority_color($pixbuf),
      '#000000',
      '1x1 transparent blue');
}
{
  my $width = 200;
  my $height = 100;
  my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_data
    ("\x00\xFF\x00\x00" x ($width * $height),
     'rgb',
     1,    # alpha
     8,    # bits
     $width,$height,
     $width * 4);   # rowstride
  is (Gtk2::Ex::PixbufBits::sampled_majority_color($pixbuf),
      '#000000',
      "${width}x${height} transparent green");
}
{
  my $width = 200;
  my $height = 100;
  my $row = ("\xFF\x00\x00" x $width) . ("\xDE\xAD\xBE" x 5000);
  my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_data
    ($row x $height,
     'rgb',
     0,    # alpha
     8,    # bits
     $width, $height,
     length($row));   # rowstride
  is (Gtk2::Ex::PixbufBits::sampled_majority_color($pixbuf),
      '#FF0000',
      "${width}x${height} red with rowstride");
}


exit 0;
