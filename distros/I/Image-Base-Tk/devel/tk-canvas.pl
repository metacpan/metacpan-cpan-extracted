#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Image-Base-Tk.
#
# Image-Base-Tk is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Tk is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Tk.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Tk;
use Tk::Mwm;
use Image::Base::Tk::Canvas;
use lib 't';

# uncomment this to run the ### lines
use Devel::Comments;


{
  my $mw = MainWindow->new;
  $mw->mwmDecorations (-title => 0,
                       -border => 0,
                       -menu => 0,
                       -maximize => 0);
  ### decor: [$mw->mwmDecorations]
  ### mw id: $mw->id
  $mw->configure(-borderwidth => 0);

  my $canvas = $mw->Canvas (-borderwidth => 0,
                            -highlightthickness => 0,
                            -width => 30,
                            -height => 15,
                            -background => 'black');
  $canvas->pack (-expand => 1, -fill => 'both');
  ### canvas id: $canvas->id

  ### borderwidth: $mw->cget('-borderwidth')
  ### borderwidth: $canvas->cget('-borderwidth')
  ### highlightthickness: $mw->cget('-highlightthickness')
  ### highlightthickness: $canvas->cget('-highlightthickness')

  my $image = Image::Base::Tk::Canvas->new
    (-tkcanvas => $canvas);

  # $image->rectangle (2,2, 4,4, 'orange', 0);
  # $image->rectangle (0,0, 0,6, 'black', 1);
  #
  # $image->rectangle (6,1, 8,10, 'black', 0);
  #  $image->xy (0,0, 'black');
  #  $image->xy (1,2, 'black');
  #  $image->xy (2,1, 'black');

  # $image->ellipse (1,1, 16,6, 'green', 1);
  # $image->diamond (1,1, 15,5, 'green', 0);

  # $image->line (12,1, 15,4, 'black');

  # my $c = $image->xy(12,1);
  # ### $c;

  # { my $str = $image->save_string;
  #   ### $str
  # }

  # $image->rectangle (0,0, 19,9, 'white', 1);
  # $image->line (10,10, 0,10, 'green', 1);
  # $image->diamond (0,0, 16,4, 'blue', 1);

  #  my @ret = $image->save('/tmp/x/x.eps');
  # ### @ret

  #$image->ellipse (5,7, 5,7, 'white', 1);
  $image->ellipse (2,2,8,8, 'white', 0);

  my $label = $canvas->Label(-text=>'E');
  # -width => 10, -height => 10
  # $canvas->createWindow (2,2, -window => $label, -anchor => 'nw');
  ### label id: $label->id

  # {
  #   # my @items = $canvas->find('overlapping', 5,7, 5,7);
  #   my @items = $canvas->find('overlapping', 2,2,2,2);
  #   ### @items
  #   my $item = $items[0];
  #   ### type: $canvas->type($item)
  #   ### fill: scalar $canvas->itemcget($item,'-fill')
  #   ### outline: scalar $canvas->itemcget($item,'-outline')
  #   ### coords: $canvas->coords($item)
  #   # my @conf = $canvas->itemconfigure($item);
  #   # ### @conf
  # }
  require MyTestHelpers;
  require MyTestImageBase;

  # {
  #   require Tk::WinPhoto;
  #   $label->update;
  #   my $photo = $label->Photo (-format => 'window',
  #                              -data => oct($label->id));
  #   require Image::Base::Tk::Photo;
  #   my $pimage = Image::Base::Tk::Photo->new
  #     (-tkphoto => $photo,
  #      -width => 30,
  #      -height => 30);
  #   $photo->write ('/dev/stdout', -format => 'xpm');
  #
  #   ### pimage size: $pimage->get('-width','-height')
  #   MyTestImageBase::dump_image($pimage);
  # }


  # MyTestImageBase::dump_image($image);
  # exit 0;

  # $canvas->delete($canvas->find('all'));
  # ### xy: $image->xy (5,7)

  MainLoop;
  exit 0;
}

{
  require Image::Base::Tk::Canvas;
  my $mw = MainWindow->new;
  my $image = Image::Base::Tk::Canvas->new
    (-for_widget => $mw,
     -width => 50,
     -height => 20,
     -file_format => 'xpm');

  $image->rectangle (0,0, 49,19, 'black');

  $image->diamond (1,1,6,6, 'white');
  $image->diamond (11,1,16,6, 'white', 1);
  $image->diamond (1,10,7,16, 'white');
  $image->diamond (11,10,17,16, 'white', 1);

  require Tk::WinPhoto;
  my $canvas = $image->get('-tkcanvas');
  $canvas->update;
  my $photo = $canvas->Photo (-format => 'window',
                              -data => oct($canvas->id));
  require Image::Base::Tk::Photo;
  my $pimage = Image::Base::Tk::Photo->new
    (-tkphoto => $photo,
     -width => 50,
     -height => 20);
  $photo->write ('/dev/stdout', -format => 'xpm');
  exit 0;
}


{
  # if area requested is in fact partly outside the screen then badmatch
  require X11::Protocol;
  my $X = X11::Protocol->new;

  my $window = $X->new_rsrc;
  $X->CreateWindow ($window,
                    $X->{'root'},     # parent
                    'InputOutput',
                    0,                # depth, from parent
                    'CopyFromParent', # visual
                    -1,-1,              # x,y
                    100,100,            # width,height
                    0,               # border
                    override_redirect => 1,
                   );
  $X->MapWindow($window);
  $X->flush;
  sleep 1;
  my @ret = $X->GetImage ($window, 1,1, 10,10, 0xFFFFFFFF, 'ZPixmap');
  ### @ret
  exit 0;
}

my $mw = MainWindow->new;
$mw->Button(-text => "Done", -command => sub { exit })->pack;




{
  my $p = $mw->Canvas; # (-width => 16, -height => 16);
#  $p->put('red', -to => 0, 0, 16, 1);

#  $p->configure(-width => 32);

  ### width: $p->width
  ### height: $p->height
  ### type: $p->type
  { my $cget = $p->cget('-format');
    ### -format: $cget
  }
  { my $cget = $p->cget('-width');
    ### -width: $cget
  }

  # {
  #   # $p->configure(-file => '/tmp/something');
  #   $p->configure(-format => 'gif');
  #   $p->write ('/tmp/something.gif');
  #   my $cget = $p->cget('-file');
  #   ### -file: $cget
  # }

  require Tk::PNG;
  $p->read ('/usr/share/emacs/23.3/etc/images/tree-widget/folder/open.png');
  ### -file read(): scalar($p->cget('-file'))
  ### width: $p->width

  # $p->configure (-file => '/usr/share/emacs/23.3/etc/images/tree-widget/folder/open.png');
  # ### -file configure(): scalar($p->cget('-file'))
  # ### width: $p->width

  my $l = $mw->Label (-image => $p);
  $l->pack;
}
# {
#   my $b = $mw->Bitmap;
#   $b->put('red', -to => 0, 0, 16, 1);
#   ### width: $b->width
#   ### height: $b->height
#   ### type: $b->type
# 
#   my $l = $mw->Label (-image => $b);
#   $l->pack;
# }

{
  my @imagetypes = $mw->imageTypes;
  ### @imagetypes
}
{
  my @imagenames = $mw->imageNames;
  ### @imagenames
}

MainLoop;
