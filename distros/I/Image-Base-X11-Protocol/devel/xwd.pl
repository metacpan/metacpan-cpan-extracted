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

use 5.010;
use strict;
use warnings;
use X11::Protocol;
use Image::Base::X11::Protocol::Pixmap;
use Image::Base::X11::Protocol::Window;

use Smart::Comments;

{
  use constant XWD_FILE_VERSION => 7;

  my $X = X11::Protocol->new;
#  ### $X
  my $rootwin = $X->{'root'};

  my $drawable = $rootwin;
  my %geom = $X->GetGeometry($drawable);
  my $depth = $geom{'depth'};
  my $width = $geom{'width'};
  my $height = $geom{'height'};
  my $border_width = $geom{'border_width'};
  $width = 200;
  $height = 200;

  my $image_format = 'ZPixmap';
  my $pixmap_format = 1;

  my %attr = $X->GetWindowAttributes($drawable);
  my $visual = $attr{'visual'}; # 0x21;
  ### $visual

  my $data = $X->GetImage ($drawable, 0,0, $width,$height,
                           0xFFFFFF, $image_format);

  my $pixmap_info = $X->{'pixmap_formats'}->{$depth};
  my $visual_info = $X->{'visuals'}->{$visual};
  my $window_name = "\0";
  my @header = (0,
                XWD_FILE_VERSION,
                $X->num('ImageFormat',$image_format),
                $depth,
                $width,
                $height,
                0,  # xoffset
                $X->{'image_byte_order'},
                $X->{'bitmap_scanline_unit'},
                $X->{'bitmap_bit_order'},
                $pixmap_info->{'scanline_pad'},
                $pixmap_info->{'bits_per_pixel'},
                0, # $bytes_per_line,
                #
                $visual_info->{'class'},
                $visual_info->{'red_mask'},
                $visual_info->{'green_mask'},
                $visual_info->{'blue_mask'},
                $visual_info->{'bits_per_rgb_value'},
                $visual_info->{'colormap_entries'},
                #
                0, # $ncolours,
                $width,
                $height,
                0, # window x
                0, # window y
                $border_width,
               );

  $header[0] = scalar(@header)*4 + length($window_name);
  my $header = pack('N*', @header) . $window_name;
  ### @header
  open FH, '>/tmp/x.xwd' or die;
  print FH $header, $data or die;
  close FH or die;
  exit 0;
}


