#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013 Kevin Ryde

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

use lib 't';
use MyTestImageBase;

{
  $ENV{'DISPLAY'} = ':0';
  my $X = X11::Protocol->new;
  $X->init_extension('SHAPE');
  { local $,=' ', say keys %{$X->{'ext'}}; }

  my $width = 20;
  my $height = 10;

  my $win = $X->new_rsrc;
  $X->CreateWindow($win, $X->root,
                   'InputOutput',
                   $X->root_depth,
                   'CopyFromParent',
                   0,0,
                   $width,$height,
                   10,   # border
                   background_pixel => $X->{'white_pixel'},
                   override_redirect => 1,
                   colormap => 'CopyFromParent',
                  );
  $X->MapWindow ($win);
  ### attrs: $X->GetWindowAttributes ($win)
  # $X->ClearArea ($win, 0,0,0,0);

  my $image = Image::Base::X11::Protocol::Window->new
    (-X => $X,
     -window => $win);
  $image->rectangle (0,0, $width-1,$height-1, 'light grey', 1);
  $image->rectangle (2,2, 17,7, 'None', 1);

  {
    my ($ordering, @rects) = $X->ShapeGetRectangles ($win, 'Clip');
    ### $ordering
    ### @rects
    my $contains = Image::Base::X11::Protocol::Window::_rects_contain_xy(0,0, @rects);
    ### $contains
  }

  foreach my $y (0 .. $height+1) {
    foreach my $x (0 .. $width+1) {
      my $ret = _window_get_shape_pixel($X, $win, $x,$y);
      print $ret;
    }
    print "\n";
  }

  $X->flush;
  $X->handle_input;
  sleep 10;
  exit 0;


  # No good.  The full set of shape region rectangles are copied to the
  # destination, so no saving in ShapeGetRectangles.
  #
  # Return 1 if the pixel of $window at $x,$y is opaque or 0 if transparent
  # due to the shape extension on $window.
  sub _window_get_shape_pixel {
    my ($X, $window, $x, $y) = @_;
    my $tempwin = $X->new_rsrc;
    $X->CreateWindow($tempwin,
                     $window,          # parent
                     'CopyFromParent', # class
                     0,                # depth, copy from parent
                     'CopyFromParent', # visual
                     0,0,              # x,y
                     1,1,
                     0,                # border
                     override_redirect => 1);
    $X->ShapeCombine ($tempwin, 'Bounding', 'Set', -$x,-$y, $window, 'Bounding');
    my ($ordering, @rects) = $X->ShapeGetRectangles ($tempwin,'Bounding');
    $X->DestroyWindow ($tempwin);
    ### @rects
    return scalar(@rects);
  }
}
{
  use X11::CursorFont;
  my $X = X11::Protocol->new(':0');
  my $rootwin = $X->root;
  my $cursor_name = 'crosshair';
  my $cursor_glyph = $X11::CursorFont::CURSOR_GLYPH{$cursor_name};
  $cursor_glyph = 32;
  my $cursor_font = $X->new_rsrc;
  $X->OpenFont ($cursor_font, "cursor"); # cursor font
  my $cursor = $X->new_rsrc;
  $X->CreateGlyphCursor ($cursor,
                         $cursor_font,  # font
                         $cursor_font,  # mask font
                         $cursor_glyph,      # glyph
                         $cursor_glyph + 1,  # and its mask
                         0,0,0,                  # foreground, black
                         0xFFFF,0xFFFF,0xFFFF);  # background, white
  $X->CloseFont ($cursor_font);

  ### $cursor_glyph
  ### $cursor
  $X->ChangeWindowAttributes($rootwin, cursor => $cursor);
  # $X->ChangeWindowAttributes($rootwin, cursor => 'None');
  $X->flush;
  exit 0;
}
{
  $ENV{'DISPLAY'} ||= ':0';
  my $X = X11::Protocol->new;
  my $rootwin = $X->root;
  my $gc = $X->new_rsrc;
  $X->CreateGC ($gc, $rootwin);
  $X->QueryPointer($rootwin);  # sync
  ### PolyLine ...
  $X->PolyLine ($rootwin, $gc, 'Origin', 0);
  ### QueryPointer ...
  $X->QueryPointer($rootwin);  # sync
  exit 0;
}

{
  $ENV{'DISPLAY'} ||= ':0';
  my $X = X11::Protocol->new;
  # ### $X
  my $rootwin = $X->{'root'};
  $X->QueryPointer($rootwin);  # sync

  my $width = 0x7FFF;
  my $height = 0x7FFF;
  my $image = Image::Base::X11::Protocol::Pixmap->new
    (-X      => $X,
     -width  => $width,
     -height => $height,
     -depth  => 1, # bitmap
    );
  $image->rectangle(0,0, $width-1,$height-1, 'set', 1);


  $image->rectangle(0,0, $width,$height, 'clear');
  ### pixel: $image->xy($width-1,$height-1)
  ### pixel: $image->xy($width-2,$height-2)

  $image->rectangle(0,0, $width-1,$height-1, 'clear', 1);
  $image->rectangle(0,0, $width-1,$height-1, 'set');
  ### pixel: $image->xy($width-1,$height-1)
  ### pixel: $image->xy($width-2,$height-2)

  $image->rectangle(0,0, $width-1,$height-1, 'clear', 1);
  ### pixel: $image->xy($width-1,$height-1)
  ### pixel: $image->xy($width-2,$height-2)

  $image->rectangle(0,0, $width-1,$height-1, 'set', 1);
  ### pixel: $image->xy($width-1,$height-1)
  ### pixel: $image->xy($width-2,$height-2)

  $X->QueryPointer($rootwin);  # sync
  x_resource_dump($X);
  undef $image;
  x_resource_dump($X);
  exit 0;
}

{
  $ENV{'DISPLAY'} = ':0';
  my $X = X11::Protocol->new;
  $X->init_extension('SHAPE');

  my $win = $X->new_rsrc;
  $X->CreateWindow($win, $X->root,
                   'InputOutput',
                   $X->root_depth,
                   'CopyFromParent',
                   0,0,
                   50,25,
                   0,   # border
                   background_pixel => $X->{'white_pixel'},
                   override_redirect => 1,
                   colormap => 'CopyFromParent',
                  );
  $X->MapWindow ($win);
  $X->ClearArea ($win, 0,0,0,0);

  my $image = Image::Base::X11::Protocol::Window->new
    (-X => $X,
     -window => $win);
  $image->rectangle (0,0, 49,24, 'black', 1);

  $image->diamond (1,1,6,6, 'white');
  $image->diamond (11,1,16,6, 'white', 1);
  $image->diamond (1,10,7,16, 'white');
  $image->diamond (11,10,17,16, 'white', 1);

  $X->flush;
  sleep 1;

  system ("xwd -id $win >/tmp/x.xwd && convert /tmp/x.xwd /tmp/x.xpm && cat /tmp/x.xpm");
  exit 0;
}


{
  $ENV{'DISPLAY'} = ':0';
  my $X = X11::Protocol->new;
  $X->init_extension('SHAPE');
  { local $,=' ', say keys %{$X->{'ext'}}; }

  my $win = $X->new_rsrc;
  $X->CreateWindow($win, $X->root,
                   'InputOutput',
                   $X->root_depth,
                   'CopyFromParent',
                   0,0,
                   100,100,
                   10,   # border
                   background_pixel => $X->{'white_pixel'},
                   override_redirect => 1,
                   colormap => 'CopyFromParent',
                  );
  $X->MapWindow ($win);
  ### attrs: $X->GetWindowAttributes ($win)
  # $X->ClearArea ($win, 0,0,0,0);

  my $image = Image::Base::X11::Protocol::Window->new
    (-X => $X,
     -window => $win);
  $image->rectangle (0,0, 99,99, 'light grey', 1);

  # $image->ellipse (10,10,50,50, 'black');
  # $image->rectangle (10,10,50,50, 'black');

  # $image->rectangle (2,2, 50,2, 'None', 0);
  # $image->rectangle (2,2, 50,50, 'None', 0);
   $image->rectangle (0,0,99,50, 'None', 1);

  # $image->ellipse (2,2, 50,50, 'None', 1);

#  $image->diamond (2,2, 50,52, 'None', 0);

  {
    my ($ordering, @rects) = $X->ShapeGetRectangles ($win, 'Bounding');
    ### $ordering
    ### @rects
    my $contains = Image::Base::X11::Protocol::Window::_rects_contain_xy(0,0, @rects);
    ### $contains
  }

  #   foreach my $i (0 .. 10) {
  #      $image->ellipse (0+$i,0+$i, 50-1*$i,50-1*$i, 'None', 1);
  #     # $image->line (0+$i,0, 50-$i,50, 'None', 1);
  #   }

  $X->flush;
  $X->handle_input;
  sleep 10;
  exit 0;
}

{
  $ENV{'DISPLAY'} ||= ':0';
  my $X = X11::Protocol->new;
  # ### $X
  my $rootwin = $X->{'root'};
  $X->QueryPointer($rootwin);  # sync

  my $image = Image::Base::X11::Protocol::Pixmap->new
    (-X      => $X,
     -width  => 2,
     -height => 2,
     -colormap => $X->{'default_colormap'},
    );
   $image = Image::Base::X11::Protocol::Window->new
    (-X      => $X,
     -window => $X->root,
    );
  $image->add_colours('#0000BA');
  $image->xy(0,0,'green');
  my @q = $X->QueryPointer($rootwin);  # sync
  ### @q
  x_resource_dump($X);
  undef $image;
  x_resource_dump($X);
  exit 0;
}

{
  # my $win = $X->new_rsrc;
  # my $image = Image::Base::X11::Protocol::Pixmap->new
  #   (-X      => $X,
  #    -width  => 0x7FFF + 50,
  #    -height => 0x7FFF + 50,
  #    -depth  => 1,
  #    # -for_drawable => $X->{'root'},
  #   );
  # ### -colormap: $image->get('-colormap')
  # $image->rectangle (0,0, 99,99, 'clear', 1);
  # 
  # $image->rectangle (10,10,50,50, 'set');
  # say $image->xy (10,10);
  exit 0;
}
{
  $ENV{'DISPLAY'} = ':0';
  my $X = X11::Protocol->new;
  ### $X
  my $rootwin = $X->{'root'};

  my $w = 0x8000;
  my $h = 20;
  my $pixmap = $X->new_rsrc;
  $X->CreatePixmap ($pixmap,
                    $X->{'root'},
                    1,  # depth
                    $w, $h);

  $X->QueryPointer($rootwin);  # sync
  exit 0;
}



{
  # zero width lines 0,0 to 0,0 draw pixel if bitmap but don't if not bitmap

  $ENV{'DISPLAY'} = ':0';
  my $X = X11::Protocol->new;
  # ### $X
  my $rootwin = $X->{'root'};
  $X->QueryPointer($rootwin);  # sync

  my $image = Image::Base::X11::Protocol::Pixmap->new
    (-X      => $X,
     -width  => 2,
     -height => 2,
     # -for_window => $X->{'root'},
     -depth  => 1,
    );
  my $pixmap = $image->get('-pixmap');
  #   my $clear = ($image->get('-depth') == 1 ? 'clear' : 'black');
  #   my $set   = ($image->get('-depth') == 1 ? 'set' : 'white');

  # $image->rectangle (0,0, 1,1, $clear, 1);
  # $image->Image_Base_Other_rectangles ($set, 0, 0,0,0,0);
  # $image->Image_Base_Other_rectangles ($set, 0, 0,0,0,0);
  # $X->QueryPointer($rootwin);  # sync

  #   my $gc = $image->get('-gc_created');

  my $gc = $X->new_rsrc;
  $X->CreateGC ($gc, $pixmap, line_width => 1);

  $X->ChangeGC ($gc, foreground => 0);
  $X->PolyFillRectangle ($pixmap, $gc, [0,0,2,2]);
  # $X->PolyPoint ($pixmap, $gc, 'Origin', 0,0, 1,1, 0,1, 1,0);

  $X->ChangeGC ($gc, foreground => 1);
  $X->PolyRectangle ($pixmap, $gc, [0,0,0,0]);

  MyTestImageBase::dump_image($image);
  exit 0;
}


{
  $ENV{'DISPLAY'} = ':0';
  my $X = X11::Protocol->new;
   ### $X
  my $win = $X->new_rsrc;
  $X->CreateWindow($win, $X->root,
                   'InputOutput',
                   $X->root_depth,
                   'CopyFromParent',
                   -20,-20,
                   100,100,
                   5,   # border
                   background_pixel => 0x123456, # $X->{'white_pixel'},
                   override_redirect => 1,
                   colormap => 'CopyFromParent',
                   save_under => 1,
                  );
  $X->MapWindow ($win);
  $X->ClearArea ($win,0,0,0,0);
  $X->ConfigureWindow ($win, stack_mode => 'Below');
  # ### attrs: $X->GetWindowAttributes ($win)

#   my $bytes = $X->GetImage($win,0,0,1,1,~0,'ZPixmap');
#   ### $bytes

  my @ret = $X->robust_req('GetImage',$win,30,30,1,1,~0,'ZPixmap');
  ### @ret

  $X->handle_input;
  exit 0;
}


{
  $ENV{'DISPLAY'} = ':0';
  my $X = X11::Protocol->new;
  #  ### $X
  $X->choose_screen(0);
  ### image_byte_order: $X->{'image_byte_order'}

  ### 0: $X->interp('Significance', 0)
  ### 1: $X->interp('Significance', 1)
  ### 2: $X->interp('Significance', 2)

  print "image_byte_order $X->{'image_byte_order'}\n";
  print "black $X->{'black_pixel'}\n";
  print "white $X->{'white_pixel'}\n";
  print "default_colormap $X->{'default_colormap'}\n";

  my $rootwin = $X->{'root'};
  print "rootwin $rootwin\n";
  my $depth = $X->{'root_depth'};
  print "depth $depth\n";
  my $colormap = $X->{'default_colormap'};

  #   my $image = Image::Base::X11::Protocol::Pixmap->new
  #     (-X => $X,
  #      -palette  => { black => $X->{'black_pixel'},
  #                     white => $X->{'white_pixel'},
  #                   },
  #      -width    => 10,
  #      -height   => 10,
  #      -depth    => $depth,
  #      -colormap => $colormap,
  #      -for_window => $rootwin);
  # #   require Data::Dumper;
  # #   print Data::Dumper->new([$image],['image'])->Dump;

  my $image = Image::Base::X11::Protocol::Drawable->new
    (-X => $X,
     -palette  => { black => $X->{'black_pixel'},
                    white => $X->{'white_pixel'},
                  },
     -depth    => $depth,
     -drawable => $rootwin);
  # -colormap => $X->{'default_colormap'});
  ### get(-colormap): $image->get('-colormap')

  print "width ",$image->get('-width'),"\n";
  print "height ",$image->get('-height'),"\n";
  print "colormap ",$image->get('-colormap'),"\n";

#   $image->rectangle (0,0, 9,9, 'light green', 1);
#   $image->line (1,1, 5,5, '#AA00AA');

  print "get xy ",$image->xy(0,0),"\n";
  exit 0;

  #   my $pixmap = $image->get('-drawable');
  #   print "-drawable $pixmap\n";
  #   $X->ChangeWindowAttributes ($rootwin, background_pixmap => $pixmap);
  #
  #   $X->ClearArea ($rootwin, 0,0,0,0);
  #
  #   undef $image;
  #
  # $X->QueryPointer($rootwin);  # sync
  #   $X->handle_input;
  #
  #   exit 0;
}
{
  $ENV{'DISPLAY'} = ':0';
  my $X = X11::Protocol->new;
  my $colormap = $X->{'default_colormap'};
  my $rootwin = $X->{'root'};
  ### geom: $X->GetGeometry($rootwin)
  exit 0;
}



{
  $ENV{'DISPLAY'} = ':0';
  my $X = X11::Protocol->new;

  my $rootwin = $X->{'root'};
  print "rootwin $rootwin\n";
  my $depth = $X->{'root_depth'};
  print "depth $depth\n";
  my $colormap = $X->{'default_colormap'};

  my $image = Image::Base::X11::Protocol::Drawable->new
    (-X        => $X,
     -drawable => $rootwin);

  my @points = (0,0) x 500000;
  $image->Image_Base_Other_xy_points ('black', @points);

  $X->QueryPointer($rootwin);  # sync
  $X->handle_input;

  exit 0;
}

{
  $ENV{'DISPLAY'} = ':0';
  my $X = X11::Protocol->new;
  my $rootwin = $X->{'root'};
  my $gc = $X->new_rsrc;
  $X->CreateGC ($gc, $rootwin);
  my $maxlen = $X->{'maximum_request_length'};
  print "maxlen $maxlen\n";
  my @points = (0,0) x 65535 - 2;
  $X->PolyPoint ($rootwin, $gc, 'Origin', @points);

  $X->QueryPointer($rootwin);  # sync
  $X->handle_input;
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



#   if (! exists $self->{'-colormap'}) {
#     my $X = $self->{'-X'};
#     my $screen_info;
#     if (defined (my $screen_num = $self->{'-for_screen'})) {
#       $screen_info = $X->{'screens'}->[$screen_num];
#     } else {
#       $screen_info
#         = _X_rootwin_to_screen_hash($X, $self->{'-drawable'})
#           || _X_rootwin_to_screen_hash($X,$self->get('-root'))
#             || croak "Oops, cannot find rootwin among screens";
#     }
#     $self->{'-colormap'} = $screen_info->{'default_colormap'};
#   }
#   return $self;
#     ### $pixel
#     if (my $gc = $self->{'-gc'}) {
#     } else {
#       my $gc = $self->{'-gc'} = $self->{'_gc_created'} = $X->new_rsrc;
#       ### CreateGC: $gc
#       $X->CreateGC ($gc, $self->{'-drawable'}, foreground => $pixel);
#     }

#   foreach my $key ('-width', '-height', '-depth') {
#     if (exists $params{$key}) {
#       croak "Attribute $key is read-only";
#     }
#   }

# =item C<-colormap> (XID integer)
# 
# The colormap to allocate colours in when drawing.  If not supplied then when
# required it's set from the colormap installed on the window
# (C<GetWindowAttributes>).  If you already know the colormap then supplying
# it in C<new> or a C<set> saves a server round-trip.




sub x_resource_dump {
  my ($X) = @_;
  $X->init_extension ('X-Resource');
  my $xid_base = $X->resource_id_base;

  printf "client 0x%X is using\n", $xid_base;

  my $ret = $X->robust_req('XResourceQueryClientResources', $xid_base);
  if (ref $ret) {
    my @resources = @$ret;
    while (@resources) {
      my $atom = shift @resources;
      my $count = shift @resources;
      my $atom_name = $X->atom_name($atom);
      printf "%6d  %s\n", $count, $atom_name;
    }
  } else {
    print "  error getting client resources\n";
  }

  $ret = $X->robust_req ('XResourceQueryClientPixmapBytes', $xid_base);
  if (ref $ret) {
    my ($bytes) = @$ret;
    printf "%6s  PixmapBytes\n", $bytes;
  } else {
    print "  error getting pixmap bytes\n";
  }

  print "\n";
}
