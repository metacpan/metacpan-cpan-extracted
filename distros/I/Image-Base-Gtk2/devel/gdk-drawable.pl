#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Gtk2 '-init';

use Smart::Comments;


{
  require Gtk2;
  require Image::Base::Gtk2::Gdk::Window;
  Gtk2->init;
  my $win = Gtk2::Gdk::Window->new (undef, { window_type => 'temp',
                                             x => 800, y => 100,
                                             width => 50, height => 25,
                                           });
  $win->show;
  $win->raise;
  $win->get_display->flush;
  sleep 1;
  my $image = Image::Base::Gtk2::Gdk::Window->new
    (-window => $win);
  $image->rectangle (0,0, 49,24, 'black', 1);

  $image->diamond (1,1,6,6, 'white');
  $image->diamond (11,1,16,6, 'white', 1);
  $image->diamond (1,10,7,16, 'white');
  $image->diamond (11,10,17,16, 'white', 1);
  $win->get_display->flush;
  sleep 1;

  my $window = $image->get('-drawable');
  print "id ",$window->XID,"\n";
  system ("xwd -id ".$window->XID." >/tmp/x.xwd && convert /tmp/x.xwd /tmp/x.xpm && cat /tmp/x.xpm");
  exit 0;
}

{
  require Image::Base::Gtk2::Gdk::Drawable;
  require Gtk2;
  Gtk2->init;
  my $rootwin = Gtk2::Gdk->get_default_root_window;
  my $image = Image::Base::Gtk2::Gdk::Drawable->new
    (-drawable => $rootwin);
  say $image->xy(0,0);
  say $image->xy(1149,3);
  exit 0;
}

{
  require Image::Base::Gtk2::Gdk::Drawable;
  require Gtk2;
  Gtk2->init;
  my $rootwin = Gtk2::Gdk->get_default_root_window;
  my $bitmap = Gtk2::Gdk::Pixmap->new (undef, 10,10, 1);
  my $image = Image::Base::Gtk2::Gdk::Drawable->new
    (-drawable => $bitmap);
  ### colormap: $bitmap->get_colormap
  $image->xy(0,0, '#FFFFFF');
  $image->xy(0,0, 'set');
  $image->xy(0,0, 'clear');
  say $image->xy(0,0);
  exit 0;
}

{
  require Gtk2;
  Gtk2->init;
#  my $rootwin = Gtk2::Gdk->get_default_root_window;
  my $rootwin = Gtk2::Gdk::Window->foreign_new (0x65);
  my $gc = Gtk2::Gdk::GC->new ($rootwin);
  ### colormap: $gc->get_colormap
  exit 0;
}


{
  require Image::Base::Gtk2::Gdk::Window;
  require Gtk2;
  Gtk2->init;
  my $rootwin = Gtk2::Gdk->get_default_root_window;
  my $image = Image::Base::Gtk2::Gdk::Window->new
    (-window => $rootwin);
  say $image->xy(00,0);
  exit 0;
}

{
  require Image::Base::Gtk2::Gdk::Window;
  require Gtk2;
  Gtk2->init;
  my $win = Gtk2::Gdk::Window->new (undef, { window_type => 'temp',
                                             x => 800, y => 100,
                                             width => 100, height => 100,
                                           });
  $win->show;
  my $image = Image::Base::Gtk2::Gdk::Window->new
    (-window => $win);

  # $image->rectangle (10,10, 50,50, 'None', 1);
  #   # $image->rectangle (0,0, 50,50, 'None', 1);
  foreach my $i (0 .. 10) {
    # $image->ellipse (0+$i,0+$i, 50-2*$i,50-2*$i, 'None', 1);
    $image->line (0+$i,0, 50-$i,50, 'None', 1);
  }

  Gtk2->main;
  exit 0;
}

{
  require Gtk2;
  Gtk2->init;
  my $rootwin = Gtk2::Gdk->get_default_root_window;
  my $pixbuf = Gtk2::Gdk::Pixbuf->get_from_drawable
    ($rootwin, undef, 800,0, 0,0, 1,1);
  ### $pixbuf
  $pixbuf->save ('/tmp/x.png', 'png');
  system ("convert  -monochrome /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm");
  exit 0;
}

{
  require Gtk2;
  Gtk2->init;
  my $rootwin = Gtk2::Gdk->get_default_root_window;
  my $colormap = $rootwin->get_colormap;
  ### $rootwin
  ### $colormap
  my $pixmap = Gtk2::Gdk::Pixmap->new ($rootwin, 10,10, -1);
  $pixmap->set_colormap($colormap);
  # $pixmap->set_colormap(undef);
  ### $pixmap
  ### colormap: $pixmap->get_colormap
  exit 0;
}


{
  my $rootwin = Gtk2::Gdk->get_default_root_window;
  my $pixmap = Gtk2::Gdk::Pixmap->new ($rootwin, 1, 1, -1);
  my @properties = $pixmap->list_properties;
  ### properties: \@properties
  exit 0;
}

{
  my $X = X11::Protocol->new;
  my $colormap = $X->{'default_colormap'};
  my $colour = 'nosuchcolour';

  print "AllocNamedColor $colormap $colormap\n";
  my @ret = $X->AllocNamedColor ($colormap, $colour);
  exit 0;
}



