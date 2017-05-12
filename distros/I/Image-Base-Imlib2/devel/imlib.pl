#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Image-Base-Imlib2.
#
# Image-Base-Imlib2 is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Imlib2 is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Imlib2.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;

# uncomment this to run the ### lines
use Smart::Comments;

{
  # jpeg compression on save()
  #
  require Image::Base::Imlib2;
  my $image = Image::Base::Imlib2->new
    (-width => 200, -height => 100,
     -file_format => 'jpeg');
  $image->ellipse (1,1, 100,50, '#0F0');
  $image->ellipse (100,50, 199,99, '#F00');
  $image->line (1,99, 199,0, '#00F');
  $image->set (-quality_percent => 1);
  $image->save ('/tmp/x-001.jpeg');
  $image->set (-quality_percent => 100);
  $image->save ('/tmp/x-100.jpeg');
  system "ls -l /tmp/x*";
  exit 0;
}

{
  for (;;) {
    require Image::Base::Imlib2;
    my $image = Image::Base::Imlib2->new;
    $image->set(-quality => 55);
  }
}


{
  # diamond
  #
  require Image::Base::Imlib2;
  my $image = Image::Base::Imlib2->new
    (-width => 50, -height => 25,
     -file_format => 'png');

  # $image->diamond (3,2, 13,2, '#0F0', 0);
  # $image->diamond (3,5, 13,5, '#0F0', 1);

#  $image->ellipse (5,6, 7,8, '#0F0', 1);
  $image->ellipse (15,16, 25,20, '#0F0', 1);

  $image->save ('/tmp/x.png');
  system ('convert /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm');
  exit 0;
}

{
  require Image::Base::Imlib2;
  my $image = Image::Base::Imlib2->new
    (-width => 50, -height => 20,
     -file_format => 'png');
  $image->rectangle (0,0, 49,29, '#000', 1);
  # $image->get('-imlib')->set_anti_alias(0);

  $image->ellipse (1,1,6,6, '#FFF');
  $image->ellipse (11,1,16,6, '#FFF', 1);
  $image->ellipse (1,10,7,16, '#FFF');
  $image->ellipse (11,10,17,16, '#FFF', 1);

  $image->save ('/tmp/x.png');
  system ('convert /tmp/x.png /tmp/x.xpm && cat /tmp/x.xpm');
  exit 0;
}


{
  # tiff write
  my $i = Imlib2->new (xsize => 200, ysize => 100);
  $i->write(file => '/tmp/x100.tiff',
            tiff_compression => 'jpeg',
            tiff_jpegquality => 100,
           )
    or die $i->errstr;
  $i->write(file => '/tmp/x001.tiff',
            tiff_compression => 'jpeg',
            tiff_jpegquality => 50)
    or die $i->errstr;
  system "ls -l /tmp/x*.tiff";
  exit 0;
}


{
  require Image::Base::Imlib2;
  my $image = Image::Base::Imlib2->new
    (-width => 20, -height => 10,
     -hotx => 7, -hoty => 8,
     -file_format => 'cur');
  $image->save ('/tmp/zz.ccc');
  $image->set (-file_format => 'ico');
  $image->save ('/tmp/zz.iii');
  $image->set (-file_format => 'cur');

  $image->set (-hotx => 3, -hoty => 4);

  # $image = Image::Base::Imlib2->new
  #   (-width => 20, -height => 10,
  #    -hotx => 3, -hoty => 4,
  #    -file_format => 'ICO');
  $image->save ('/tmp/zz2.xyz');

  $image = Image::Base::Imlib2->new
    (-file => '/tmp/zz2.xyz');
  ### -file_format: $image->get('-file_format')

  # ### read_types: sort Imlib2->read_types
  # ### write_types: sort Imlib2->write_types
  # my $iformats = \%Imlib2::formats;
  # ### $iformats

  exit 0;
}


{
  my $i = Imlib2->new (xsize => undef, ysize => undef);
  ### $i
  ### errstr: Imlib2->errstr
  ### width: $i->getwidth
  ### height: $i->getheight
  $i->settag (name => 'i_format', value => 'CUR');
  $i->settag (name => 'cur_hotspotx', value => 5);
  ### tags: [$i->tags]
  exit 0;
}
{
  print join(',', sort Imlib2->write_types), "\n";
  my $i = Imlib2->new(xsize=>1,ysize=>1);
  my @ret = $i->write (file => '/tmp/x.png',
                       # type => 'fjdkslfsjkl',
                      );
  ### @ret
  print join(',', sort Imlib2->write_types), "\n";
  exit 0;
}




{
  ### read_types: sort Imlib2->read_types
  ### write_types: sort Imlib2->write_types
  exit 0;
}





{
  foreach my $c (scalar (Imlib2::Color->new(xname => 'pink')),
                 scalar (Imlib2::Color->new(gimp => 'pink')),
                 scalar (Imlib2::Color->new(builtin => 'pink')),
                 scalar (Imlib2::Color->new(name => 'green')),
                ) {
    ### $c
    ### rgba: $c && $c->rgba
  }
  exit 0;
}


