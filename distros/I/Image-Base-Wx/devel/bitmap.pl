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
  # bitmap free before DC
  my $wxbitmap = Wx::Bitmap->new (20, 10);
  my $dc = Wx::MemoryDC->new;
  $dc->SelectObject($wxbitmap);
  $dc->IsOk or die;
  undef $wxbitmap;
  ### $dc
  ### depth: $dc->GetDepth
  $dc->Clear;
  ### GetObject: $dc->GetObject
  undef $dc;
  ### $wxbitmap
  
  exit 0;
}
{
  # failed load of each format
  my $filename = '/dev/null';
  my $wxbitmap = Wx::Bitmap->new (20, 10);
  foreach my $file_format (qw(BMP
                              GIF
                              JPEG
                              PCX
                              PNG
                              PNM
                              TIF
                              CUR
                              ICO
                              XPM
                              ANI
                            )) {
    ### $file_format
    my $type = eval "Wx::wxBITMAP_TYPE_${file_format}()";
    my $ret = $wxbitmap->LoadFile($filename,$type);
  }
  exit 0;
}

{
  # read
  # Wx::InitAllImageHandlers();
  #Wx::Image::AddHandler (Wx::PNGHandler->new);
  #Wx::Image::AddHandler (Wx::GIFHandler->new);

  my $filename = '/usr/share/doc/wx2.8-examples/examples/samples/dnd/wxwin.png';
  $filename = '/usr/share/doc/wx2.8-examples/examples/samples/access/mondrian.xpm';
  $filename = '/usr/share/pyshared/pygame/pygame_icon.tiff';
  $filename = '/usr/share/doc/dhttpd/dhttpd102.gif';
  my $wxbitmap = Wx::Bitmap->new (20, 10);
  print "any ",Wx::wxBITMAP_TYPE_ANY(),"\n";
  print "xpm ",Wx::wxBITMAP_TYPE_XPM(),"\n";
  {
    my $ret = $wxbitmap->LoadFile($filename,Wx::wxBITMAP_TYPE_PNG());
    ### $ret
    ### width: $wxbitmap->GetWidth
  }
  {
    my $ret = $wxbitmap->LoadFile($filename,Wx::wxBITMAP_TYPE_TIF());
    ### $ret
    ### width: $wxbitmap->GetWidth
  }
  {
    my $ret = $wxbitmap->LoadFile($filename,Wx::wxBITMAP_TYPE_GIF());
    ### $ret
    ### width: $wxbitmap->GetWidth
  }
  {
    my $ret = $wxbitmap->LoadFile($filename,Wx::wxBITMAP_TYPE_ANY());
    ### $ret
    ### width: $wxbitmap->GetWidth
  }
  {
    my $ret = $wxbitmap->LoadFile($filename,Wx::wxBITMAP_TYPE_XPM());
    ### $ret
    ### width: $wxbitmap->GetWidth
  }
  exit 0;
}

__END__

{
  # read Image::Base::Wx::Bitmap
  Wx::InitAllImageHandlers();
  require Image::Base::Wx::Bitmap;
  my $image = Image::Base::Wx::Bitmap->new
    (-file => '/usr/share/doc/wx2.8-examples/examples/samples/dnd/wxwin.png');
  ### $image
  exit 0;
}

{
  # write

  Wx::InitAllImageHandlers();
  {
    my $handler = Wx::Bitmap::FindHandlerType(Wx::wxBITMAP_TYPE_BMP());
    ### $handler
  }
  my $wxbitmap = Wx::Bitmap->new (20, 10);
  # system ('cat /tmp/x.bmp');
  {
    my $ret = $wxbitmap->LoadFile('/usr/share/doc/wx2.8-examples/examples/samples/access/mondrian.xpm',Wx::wxBITMAP_TYPE_XPM());
    ### $ret
    ### width: $wxbitmap->GetDepth
  }
  {
    my $ret = $wxbitmap->SaveFile('/tmp/x.bmp',Wx::wxBITMAP_TYPE_BMP());
    ### $ret
  }
  exit 0;
}
{
  # transparent
  Wx::InitAllImageHandlers();
  require Image::Base::Wx::Bitmap;
  { my $image = Image::Base::Wx::Bitmap->new
      (-width  => 20,
       -height => 10,
       -file_format => 'png');
    ### $image

    my $wxbitmap = $image->get('-wxbitmap');
    $wxbitmap->InitAlpha;
    ### HasAlpha: $wxbitmap->HasAlpha

    $image->rectangle (5,5, 10,8, 'none', 1);
    $image->rectangle (19,9, 19,9, 'None', 1);
    $image->rectangle (6,6, 7,7, 'green', 1);
    $image->save('/tmp/x.png');
    system ('convert /tmp/x.png /tmp/x.xpm');
    system ('cat /tmp/x.xpm');
  }
  exit 0;
}
