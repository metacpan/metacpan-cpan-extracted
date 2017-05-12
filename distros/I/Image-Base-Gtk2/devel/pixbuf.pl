#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Gtk2.
#
# Image-Base-Gtk2 is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Gtk2 is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Gtk2.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Gtk2;

use Smart::Comments;


{
  # rectangle off-screen
  require Image::Base::Gtk2::Gdk::Pixbuf;
  my $image = Image::Base::Gtk2::Gdk::Pixbuf->new
    (-width => 50, -height => 20,
     -file_format => 'png');
  $image->rectangle (0,0, 49,29, 'black',1);

  $image->rectangle (-10,-10,6,6, 'white',1);

  $image->save('/tmp/x.png');
  system ("convert  -monochrome /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm");
  exit 0;
}

{
  my $data = "\x{FF}\x{FF}\x{FF}\x{FF}";
  my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_data
    ($data x 100,
     'rgb', # colorspace
     1,     # has_alpha
     8,     # bits per sample
     10,10,   # width,height
     2);   # rowstride
  ### $pixbuf
  ### pixels: $pixbuf->get_pixels
  ### rowstride: $pixbuf->get_rowstride

  my $pspec = $pixbuf->find_property('rowstride');
  ### $pspec
  ### min: $pspec->get_minimum

  exit 0;
}
{
  # jpeg compression on save()
  #
  require Image::Base::Gtk2::Gdk::Pixbuf;
  my $image = Image::Base::Gtk2::Gdk::Pixbuf->new
    (-width => 200, -height => 100,
     -file_format => 'jpeg');
  $image->ellipse (1,1, 100,50, 'green');
  $image->ellipse (100,50, 199,99, 'orange');
  $image->line (1,99, 199,0, 'red');
  $image->set (-quality_percent => 1);
  $image->save ('/tmp/x-001.jpeg');
  $image->set (-quality_percent => 100);
  $image->save ('/tmp/x-100.jpeg');
  system "ls -l /tmp/x*";
  exit 0;
}
{
  my @formats = Gtk2::Gdk::Pixbuf->get_formats;
  # ### @formats
  # @formats = grep {$_->{'is_writable'}} @formats;
  @formats = map {$_->{'name'}} @formats;
  ### @formats
  exit 0;
}

{
  my %uniq;
  foreach my $format (Gtk2::Gdk::Pixbuf->get_formats) {
    my @extensions = @{$format->{'extensions'}};
    { local $, = ' '; print @extensions; }
    print "\n";

    foreach my $ext (@extensions) {
      if ($uniq{$ext}++) {
        die "not unique: $ext";
      }
    }
  }
  exit 0;
}
{
  require Image::Xpm;
  my $i = Image::Xpm->new (-hotx => 0,
                           # -hoty => 1,
                           -width => 2,
                           -height => 3);
  $i->save ('/tmp/x.xpm');
  system ('cat /tmp/x.xpm');

  my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_file ('/tmp/x.xpm');
  ### x_hot: $pixbuf->get_option('x_hot')
  ### y_hot: $pixbuf->get_option('y_hot')
  exit 0;
}
{
  my $pixbuf = Gtk2::Gdk::Pixbuf->new
    ('rgb', # colorspace
     0,     # has_alpha
     8,     # bits per sample
     2,3);  # width,height
  $pixbuf->fill (0xFFAA00AA);
  #   $pixbuf->set_option (x_hot => 3);
  #   $pixbuf->set_option (y_hot => 4);
  $pixbuf->save('/dev/stdout', 'xpm',
                #                 x_hot => 0,
                #                 y_hot => 1,
               );
  exit 0;
}

{
  my $pixbuf = Gtk2::Gdk::Pixbuf->new
    ('rgb', # colorspace
     0,     # has_alpha
     8,     # bits per sample
     2,3);  # width,height
  $pixbuf->fill (0xFFAA00AA);
  #   $pixbuf->set_option (x_hot => 3);
  #   $pixbuf->set_option (y_hot => 4);
  #   $pixbuf->save('/tmp/x.xpm', 'xpm');
  $pixbuf->save('/tmp/x.ico', 'ico',
                x_hot => 0,
                y_hot => 1);

  open my $fh, '/tmp/x.ico' or die;
  my $buf;
  read $fh, $buf, 9999 or die;
  print "(\"";
  for (my $i = 0; $i < length($buf); $i++) {
    printf "\\x{%02X}", ord(substr($buf,$i,1));
    if (($i % 8) == 7) {
      print "\"\n. \"";
    }
  }
  print "\");\n";
  exit 0;
}


{
  my $colorobj = Gtk2::Gdk::Color->parse('blue');
  ### $colorobj
  exit 0;
}

{
  my $data = "\x{FF}\x{FF}\x{FF}\x{FF}";
  my $pixbuf = Gtk2::Gdk::Pixbuf->new_from_data
    ($data,
     'rgb', # colorspace
     1,     # has_alpha
     8,     # bits per sample
     1,1,   # width,height
     4);    # rowstride
  ### pixels: $pixbuf->get_pixels

  $data = "\x{01}\x{02}\x{03}\x{00}";
  my $src_pixbuf = Gtk2::Gdk::Pixbuf->new_from_data
    ($data,
     'rgb', # colorspace
     1,     # has_alpha
     8,     # bits per sample
     1,1,   # width,height
     4);    # rowstride
  $src_pixbuf->copy_area (0,0, # src x,y
                          1,1,   # src width,height
                          $pixbuf,
                          0,0,       # src offset x,y
                         );

  ### pixels: $pixbuf->get_pixels
  exit 0;
}


#     $src_pixbuf->composite ($pixbuf,
#                             $x,$y, # dest x,y
#                             1,1,   # dest width,height
#                             0,0,       # src offset x,y
#                             1.0,1.0,   # src scale x,y
#                             'nearest', # GdkInterpType
#                             255);      # overall alpha
