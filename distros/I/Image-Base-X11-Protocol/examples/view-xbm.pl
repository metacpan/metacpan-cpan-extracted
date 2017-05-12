#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-X11-Protocol.
#
# Image-Base-X11-Protocol is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Image-Base-X11-Protocol is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-X11-Protocol.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl view-xbm.pl filename
#
# For example: perl view-xbm.pl /usr/share/pixmaps/lookup-el/lookup-logo.xbm
#
# This is a few lines demonstrating how to make a pixmap image out of
# another Image::Base, in this case an Image::Xbm.
#
# The operative part is the new_from_image().  It's very slow, because
# new_from_image() copies the image contents pixel by pixel.
#
# Image::Xbm xy() returns its pixels as colour names "black" and "white", so
# the destination Image::Base::X11::Protocol::Pixmap must have a '-colormap'
# to lookup/create pixel values to display those.  The "-for_window"
# shorthand establishes the necessary settings.
#
# Maybe the speed would be improved by new_from_image() watching for runs of
# the same colour and drawing that on the destination with ->line(), or if
# runs of whole rows then ->rectangle().
#

BEGIN { require 5; }
use strict;
use Image::Xbm;
use X11::Protocol;
use Image::Base::X11::Protocol::Pixmap;

if (@ARGV != 1) {
  print "Usage: perl view-xbm.pl filename\n";
}
my $filename = $ARGV[0];

my $image_xbm = Image::Xbm->new (-file => $filename);

my $X = X11::Protocol->new;
my $image_pixmap = $image_xbm->new_from_image
  ('Image::Base::X11::Protocol::Pixmap',
   -X => $X,
   -for_window => $X->root);  # visual and colormap

my $window = $X->new_rsrc;
$X->CreateWindow ($window, $X->root,
                  'InputOutput',
                  $X->root_depth,
                  'CopyFromParent',
                  0,0,
                  $image_pixmap->get('-width','-height'),
                  10,   # border
                  background_pixmap => $image_pixmap->get('-drawable'),
                  colormap => 'CopyFromParent',
                 );
$X->ChangeProperty($window,
                   $X->atom('WM_NAME'),  # property
                   $X->atom('STRING'),   # type
                   8,                    # byte format
                   'Replace',
                   'view-xbm.pl');       # window title
$X->MapWindow ($window);

for(;;) {
  $X->handle_input;
}
exit 0;
