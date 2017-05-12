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
  # transparent
  Wx::InitAllImageHandlers();
  require Image::Base::Wx::Image;
  { my $image = Image::Base::Wx::Image->new
      (-width  => 20,
       -height => 10,
       -file_format => 'png');

    my $wximage = $image->get('-wximage');
    $wximage->InitAlpha;
    ### HasAlpha: $wximage->HasAlpha

    $image->rectangle (5,5, 10,8, 'none', 1);
    $image->rectangle (19,9, 19,9, 'None', 1);
    $image->rectangle (6,6, 7,7, 'green', 1);
    $image->save('/tmp/x.png');
    system ('convert /tmp/x.png /tmp/x.xpm');
    system ('cat /tmp/x.xpm');
  }
  exit 0;
}
{
  # CUR -hotx
  Wx::InitAllImageHandlers();
  require Image::Base::Wx::Image;
  my $image = Image::Base::Wx::Image->new
    (-file => '/usr/lib/perl5/Tk/demos/images/cursor.cur');
  ### hotx: $image->get('-hotx')
  ### hoty: $image->get('-hoty')
  ### quality_percent: $image->get('-quality_percent')

  my $wximage = $image->get('-wximage');
  foreach my $option (Wx::wxIMAGE_OPTION_BMP_FORMAT(),
                      Wx::wxIMAGE_OPTION_FILENAME(),
                      Wx::wxIMAGE_OPTION_CUR_HOTSPOT_X(),
                      Wx::wxIMAGE_OPTION_CUR_HOTSPOT_Y(),
                      Wx::wxIMAGE_OPTION_QUALITY(),
                      Wx::wxIMAGE_OPTION_BITSPERSAMPLE(),
                      'blah',
                     ) {
    my $have = $wximage->HasOption($option);
    my $value = $wximage->GetOption($option);
    my $int = $wximage->GetOptionInt($option);
    ### $option
    ### $have
    ### $value
    ### $int
  }
  exit 0;
}

{
  # XPM doesn't read a hotspot, only CUR
  Wx::InitAllImageHandlers();
  my $image = Wx::Image->new;
  # {
  #   open my $fh, '<',
  #     '/usr/share/icewm/themes/Infadel2/cursors/move.xpm'
  #       or die;
  #   my $handler = Wx::XPMHandler->new;
  #   my $ret = $handler->LoadFile($image, $fh);
  #   ### $ret;
  #   ### width: $image->GetWidth
  #   ### height: $image->GetHeight
  # }
  {
    my $ret = $image->LoadFile('/usr/lib/perl5/Tk/demos/images/cursor.cur',
                               Wx::wxBITMAP_TYPE_ANY());
    # my $ret = $image->LoadFile('/usr/share/icewm/themes/Infadel2/cursors/move.xpm',
    #                            Wx::wxBITMAP_TYPE_ANY());
    ### $ret;
    ### width: $image->GetWidth
    ### height: $image->GetHeight
    $image->SetOption(blah => 'abc');
  }
  foreach my $option (Wx::wxIMAGE_OPTION_BMP_FORMAT(),
                      Wx::wxIMAGE_OPTION_FILENAME(),
                      Wx::wxIMAGE_OPTION_CUR_HOTSPOT_X(),
                      Wx::wxIMAGE_OPTION_CUR_HOTSPOT_Y(),
                      Wx::wxIMAGE_OPTION_QUALITY(),
                      Wx::wxIMAGE_OPTION_BITSPERSAMPLE(),
                      'blah',
                     ) {
    my $have = $image->HasOption($option);
    my $value = $image->GetOption($option);
    my $int = $image->GetOptionInt($option);
    ### $option
    ### $have
    ### $value
    ### $int
  }

  exit 0;
}
{
  # JPEG quality
  Wx::InitAllImageHandlers();
  require Image::Base::Wx::Image;
  { my $image = Image::Base::Wx::Image->new
      (-width  => 200,
       -height => 100,
       -file_format => 'jpeg');
    $image->rectangle (10,10, 50,50, 'orange');
    $image->set(-quality_percent => 100);
    $image->save('/tmp/x1.jpg');
    $image->set(-quality_percent => 0);
    $image->save('/tmp/x2.jpg');
  }
  { my $image = Image::Base::Wx::Image->new
      (-file => '/tmp/x1.jpg',
       -load_verbose => 1);
    ### $image
  }
  exit 0;
}
{
  # read png
  Wx::Image::AddHandler (Wx::PNGHandler->new);
  require Image::Base::Wx::Image;
  my $image = Image::Base::Wx::Image->new
    (-file => '/usr/share/doc/wx2.8-examples/examples/samples/dnd/wxwin.png');
  ### $image
  exit 0;
}
{
  my $handler = Wx::PNGHandler->new;
  my $image = Wx::Image->new;
  ### $image
  ### width: $image->GetWidth
  ### height: $image->GetHeight

  {
    open my $fh, '<',
      '/usr/share/doc/wx2.8-examples/examples/samples/dnd/wxwin.png'
        or die;
    binmode $fh;
    my $ret = $handler->LoadFile($image, $fh);
    ### $ret;
    ### width: $image->GetWidth
    ### height: $image->GetHeight
  }
  {
    open my $fh, '>', '/tmp/x.png' or die;
    my $ret = $handler->SaveFile($image, $fh);
    ### $ret;
  }
  {
    my $ret = $image->SaveFile('/tmp/x.png', Wx::wxBITMAP_TYPE_TIF());
    ### $ret;
  }
  {
    Wx::InitAllImageHandlers();
    my $ret = $image->SaveFile('/tmp/x.xpm');
    ### $ret;
  }
  exit 0;
}


