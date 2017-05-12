#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-Prima.
#
# Image-Base-Prima is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Prima is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Prima.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
# use blib "$ENV{HOME}/perl/prima/Prima-1.29/blib";
use lib "$ENV{HOME}/perl/prima/Prima-1.29_01/inst/local/lib/perl/5.10.1/";
# use Prima::noX11;

use Smart::Comments;

use Prima;
### version: Prima->VERSION


{
  {  my $i = Prima::Image->new (width => 1000, height => 1000);
     $i->{'extras'}->{'XHotSpot'} = 0x42;
     $i->{'extras'}->{'YHotSpot'} = 0x43;
     $i->save ('/tmp/x.bmp')
       or die "Error saving: $@\n";
   }
  {
    my $i = Prima::Image->new;
    $i->load ('/tmp/x.bmp', loadExtras => 1)
      or die "Error saving: $@\n";
    ### extras: $i->{'extras'}

    $i->{'extras'}->{'XHotSpot'} = 0x44;
    $i->{'extras'}->{'YHotSpot'} = 0x45;
    $i->save ('/tmp/y.bmp')
      or die "Error saving: $@\n";

    # require Image::Base::Prima::Image;
    # my $bmp_codecID = Image::Base::Prima::Image::_format_to_codecid('BMP');
    #
    # $i->{'extras'}->{'codecID'} = $bmp_codecID;
    # $i->load ('/z/so/gtk/gtk+-2.0.0/gdk/win32/rc/gtk.ico', loadExtras => 1)
    #   or die "Error saving: $@\n";
    # ### extras: $i->{'extras'}
  }

  {
    my $i = Prima::Image->new;
    $i->load ('/tmp/y.bmp', loadExtras => 1)
      or die "Error loading: $@\n";
    ### y extras: $i->{'extras'}
  }
  exit 0;
}


{
  require Image::Base::Prima::Image;
  my $i = Image::Base::Prima::Image->new (-file => '/usr/lib/perl5/Tk/demos/images/cursor.xbm');
  ### hotx: $i->get('-hotx')
  ### hoty: $i->get('-hoty')
  exit 0;
}

{
  my $i = Prima::Image->new;
  $i->load ('/usr/lib/perl5/Tk/demos/images/cursor.xbm', loadExtras => 1)
    or die "Error loading: $@\n";
  ### extras: $i->{'extras'}
  exit 0;
}
