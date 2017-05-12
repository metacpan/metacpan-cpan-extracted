#!/usr/bin/perl -w

# Copyright 2013 Kevin Ryde

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
use Geometry::AffineTransform;
use List::Pairwise 'mapp';
use X11::Protocol;
use X11::Protocol::WM;
use X11::CursorFont;
use Image::Base::X11::Protocol::Drawable;

# uncomment this to run the ### lines
# use Smart::Comments;


my $X = X11::Protocol->new;
$X->init_extension('DOUBLE-BUFFER') or die;
my $rootwin = $X->root;

my $width = 500;
my $height = 500;
my $affine = Geometry::AffineTransform->new;
$affine->scale($width/0x10000/2, $height/0x10000/2);
$affine->translate($width/2, $height/2);
my $unaffine = $affine->clone->invert;

my $cursor_name = 'left_ptr';
my $cursor_glyph = $X11::CursorFont::CURSOR_GLYPH{$cursor_name};
my $cursor_font = $X->new_rsrc;
$X->OpenFont ($cursor_font, "cursor"); # cursor font
my $cursor = $X->new_rsrc;
$X->CreateGlyphCursor
  ($cursor,
   $cursor_font,  # font
   $cursor_font,  # mask font
   $cursor_glyph,      # glyph
   $cursor_glyph + 1,  # and its mask
   0,0,0,                  # foreground, black
   0xFFFF,0xFFFF,0xFFFF);  # background, white
$X->CloseFont ($cursor_font);

my $colormap = $X->default_colormap;
### $colormap

my $window = $X->new_rsrc;
$X->CreateWindow($window,
                 $X->root,         # parent
                 'InputOutput',    # class
                 $X->root_depth,   # depth
                 'CopyFromParent', # visual
                 0,0,              # x,y
                 $width,$height,
                 0,                # border
                 background_pixel => $X->black_pixel,
                 colormap         => $colormap,
                 event_mask       => $X->pack_event_mask('Exposure',
                                                         'ButtonPress',
                                                         'Button1Motion',
                                                         'ButtonRelease',
                                                        ),
                );
X11::Protocol::WM::set_wm_name ($X, $window, 'Line Clip'); # title
X11::Protocol::WM::set_wm_icon_name ($X, $window, 'LClip');
X11::Protocol::WM::set_wm_client_machine_from_syshostname ($X, $window);
X11::Protocol::WM::set_net_wm_pid ($X, $window);

my $buffer = $X->new_rsrc;
$X->DbeAllocateBackBufferName ($window, $buffer, 'Background');

my $foreground_colour = 'white';
my $foreground_pixel = $X->white_pixel;
my $background_pixel = $X->black_pixel;
my ($grey_pixel)  = $X->AllocColor ($colormap, 0x4000,0x4000,0x4000);
my ($red_pixel)   = $X->AllocColor ($colormap, 0xFFFF,0,0);
my ($green_pixel) = $X->AllocColor ($colormap, 0,0xFFFF,0);

my $image = Image::Base::X11::Protocol::Drawable->new
  (-X        => $X,
   -drawable => $buffer,
   -colormap => $colormap,
  );

my $gc = $X->new_rsrc;
$X->CreateGC ($gc, $window,
              # don't want NoExpose events when copying from $window
              graphics_exposures => 0,
              fill_style => 'Solid',
             );

my $want_expose;

my @lx = (-0xE000, 0x4000);
my @ly = (-0xC000, 0x6000);
my ($drag_i, $drag_x, $drag_y);

sub hypot_dist {
  my ($x1,$y1, $x2,$y2) = @_;
  return sqrt(($x1-$x2)**2 + ($y1-$y2)**2);
}

my $state_control = (1 << $X->num('KeyMask','Control'));
### $state_control

sub drag_motion {
  my ($wx,$wy, $state) = @_;
  ### drag_xy(): "$wx,$wy"
  if (! defined $drag_x) {
    ### drag not active ...
    return;
  }
  my ($lx,$ly) = $unaffine->transform($wx,$wy);
  my $x_offset = $lx - $drag_x;
  my $y_offset = $ly - $drag_y;
  $lx[$drag_i] += $x_offset;
  $ly[$drag_i] += $y_offset;
  if ($state & $state_control) {
    $lx[$drag_i^1] += $x_offset;  # other end too
    $ly[$drag_i^1] += $y_offset;
  }
  $drag_x = $lx;
  $drag_y = $ly;
  $want_expose = 1;
}

$X->{'event_handler'} = sub {
  my (%h) = @_;
  ### event_handler: \%h

  if ($h{'name'} eq 'Expose') {
    $want_expose = 1;

  } elsif ($h{'name'} eq 'ButtonPress') {
    my ($x,$y) = $unaffine->transform($h{'event_x'},$h{'event_y'});
    my $i = (hypot_dist($x,$y, $lx[0],$ly[0])
             < hypot_dist($x,$y, $lx[1],$ly[1])
             ? 0 : 1);
    $drag_x = $x;
    $drag_y = $y;
    $drag_i = $i;
    $X->ChangeWindowAttributes ($window, cursor => $cursor);

  } elsif ($h{'name'} eq 'MotionNotify') {
    drag_motion($h{'event_x'},$h{'event_y'}, $h{'state'});

  } elsif ($h{'name'} eq 'ButtonRelease') {
    drag_motion($h{'event_x'},$h{'event_y'}, $h{'state'});
    $X->ChangeWindowAttributes ($window, cursor => 'None');
    undef $drag_x;
  }
};

$X->MapWindow ($window);


sub diamond_poly {
  my ($x1,$y1, $x2,$y2) = @_;

  my $xh = ($x2 - $x1);
  my $yh = ($y2 - $y1);
  my $xeven = ($xh & 1);
  my $yeven = ($yh & 1);
  $xh = int($xh / 2);
  $yh = int($yh / 2);

  return [ $x1+$xh, $y1,  # top centre

           # left
           $x1, $y1+$yh,
           ($yeven ? ($x1, $y2-$yh) : ()),

           # bottom
           $x1+$xh, $y2,
           ($xeven ? ($x2-$xh, $y2) : ()),

           # right
           ($yeven ? ($x2, $y2-$yh) : ()),
           $x2, $y1+$yh,

           ($xeven ? ($x2-$xh, $y1) : ()),
           $x1+$xh, $y1  # back to start
         ];
}


for (;;) {
  $X->handle_input;

  if ($want_expose) {
    ### expose draw ...
    # $X->ClearArea ($buffer, 0,0,0,0); # whole window
    $X->QueryPointer($rootwin);
    $X->ChangeGC ($gc, foreground => $grey_pixel);

    # rectangles
    {
      my ($wx1,$wy1) = $affine->transform(-0x8000,-0x8000);
      my ($wx2,$wy2) = $affine->transform(0x7FFF,0x7FFF);
      ### rect: $wx1,$wy1
      $X->PolyRectangle ($buffer, $gc, [ $wx1,$wy1, $wx2-$wx1, $wy2-$wy1 ]);
    }
    {
      my ($wx,$wy) = $affine->transform(0,0);
      $X->PolyLine ($buffer, $gc, 'Origin', $wx,0x7FFF, $wx,$wy, 0x7FFF,$wy);
    }

    if (1) {
      # diamond
      {
        my $aref = diamond_poly($lx[0],$ly[0], $lx[1],$ly[1]);
        { my @w = mapp {$affine->transform($a,$b)} @$aref;
          $X->PolyLine ($buffer, $gc, 'Origin', @w); }

        Image::Base::X11::Protocol::Drawable::_convex_poly_clip($aref);
        ### $aref
        { my @w = mapp {$affine->transform($a,$b)} @$aref;
          ### @w
          $X->ChangeGC ($gc, foreground => $foreground_pixel);
          $X->PolyLine ($buffer, $gc, 'Origin', @w); }
      }
    }

    if (0) {
      # line unclipped
      {
        ### transform to: $affine->transform($lx[0],$ly[0])
        $X->PolyLine ($buffer, $gc, 'Origin',
                      $affine->transform($lx[0],$ly[0]),
                      $affine->transform($lx[1],$ly[1]));
      }
      # flag any positive
      {
        my $any_pos = Image::Base::X11::Protocol::Drawable::_line_any_positive
          ($lx[0],$ly[0], $lx[1],$ly[1]);
        $X->ChangeGC ($gc, foreground => $any_pos ? $green_pixel : $red_pixel);
        $X->PolyFillRectangle ($buffer, $gc, [ 0,0, 10,10 ]);
      }
      # line
      {
        my ($cx1,$cy1, $cx2,$cy2)
          = Image::Base::X11::Protocol::Drawable::_line_clip
            ($lx[0],$ly[0], $lx[1],$ly[1]);
        if (defined $cx1) {
          if ($cx1 > 0x7FFF || $cx1 < -0x8000
              || $cy1 > 0x7FFF || $cy1 < -0x8000
              || $cx2 > 0x7FFF || $cx2 < -0x8000
              || $cy2 > 0x7FFF || $cy2 < -0x8000
             ) {
            die "clip outside 2^16  $cx1, $cy1   $cx2, $cy2";
          }
        }
        if (defined $cx1) {
          $X->ChangeGC ($gc, foreground => $foreground_pixel);
          $X->PolyLine ($buffer, $gc, 'Origin',
                        $affine->transform($cx1,$cy1),
                        $affine->transform($cx2,$cy2));
        }
        # $image->line($affine->transform($lx[0],$ly[0]),
        #              $affine->transform($lx[1],$ly[1]),
        #              $foreground_colour);

        # flag whether clip leaves anything
        {
          $X->ChangeGC ($gc, foreground=>defined($cx1)?$green_pixel:$red_pixel);
          $X->PolyFillRectangle ($buffer, $gc, [ 15,0, 10,10 ]);
        }
      }
    }

    $X->DbeSwapBuffers ($window, 'Background');

    # sync
    $X->QueryPointer($rootwin);
  }
}

exit 0;
