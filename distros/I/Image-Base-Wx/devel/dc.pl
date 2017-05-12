#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Wx.
#
# Image-Base-Wx is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Wx is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Wx.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use Wx;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $colour_obj = Wx::Colour->new('RGB(9991,2,3)');
  ### $colour_obj
  ### isok: $colour_obj->IsOk
  ### red: $colour_obj->Red
  ### green: $colour_obj->Green
  ### blue: $colour_obj->Blue
  exit 0;
}
{
  require Image::Base::Wx::DC;

  my $bitmap = Wx::Bitmap->new (21,10);
  my $dc = Wx::MemoryDC->new;
  $dc->SelectObject($bitmap);
  $dc->IsOk or die;

  my $pen = $dc->GetPen;
  $pen->SetCap(Wx::wxCAP_PROJECTING());
  $dc->SetPen($pen);

  my $image = Image::Base::Wx::DC->new
    (-dc => $dc,
     # -width => 21, -height => 10,
    );
  my $black = 'black';
  $MyTestImageBase::white = 'white';
  $MyTestImageBase::white = 'white';
  $MyTestImageBase::black = $black;
  $MyTestImageBase::black = $black;
  my ($width, $height) = $image->get('-width','-height');
  ### $width
  ### $height

  $image->xy (-100,-100);
  ### fetch xy(): $image->xy (-100,-100)

  # $image->rectangle (0,0, $width-1,$height-1, $black, 1);
  # $image->line (5,5, 7,7, 'white', 0);
  #
  # $image->rectangle (0,0, $width-1,$height-1, $black, 1);

  use lib 't';
  require MyTestImageBase;
  MyTestImageBase::dump_image($image);

  {
    my ($size) = $dc->GetSize;
    ### $size
    ### width: $size->GetWidth
    ### height: $size->GetHeight
  }
  {
    my ($size) = $dc->GetSize;
    ### $size
    ### width: $size->GetWidth
    ### height: $size->GetHeight
  }

  exit 0;
}

