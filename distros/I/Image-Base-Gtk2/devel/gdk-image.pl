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
  Gtk2->init;
  foreach my $visual (
                      Gtk2::Gdk::Visual->get_best,
                      Gtk2::Gdk->list_visuals,
                      Gtk2::Gdk::Screen->get_default->list_visuals,
                     ) {
    ### $visual
    ### type: $visual->type
    ### depth: $visual->depth
  }

  foreach my $depth (0 .. 128) {
    my $visual = Gtk2::Gdk::Visual->get_best_with_depth($depth);
    if ($visual) {
      ### $depth
      ### $visual
      ### type: $visual && $visual->type
      ### depth: $visual && $visual->depth
    }
  }
  exit 0;
}

{
  require Image::Base::Gtk2::Gdk::Image;
  require Gtk2;
  Gtk2->init;
  Gtk2::Gdk::Image->can('get_colormap') or die "No GdkImage";

  my $image = Image::Base::Gtk2::Gdk::Image->new
    (-width => 100,
     -height => 50);
  say $image->get('-width');
  say $image->get('-height');
  say $image->get('-visual');
  say $image->get('-colormap')//'undef';
  say $image->get('-depth');
  say $image->xy(0,0);
  exit 0;
}




