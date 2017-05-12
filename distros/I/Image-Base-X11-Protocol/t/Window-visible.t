#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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


# Fetching back pixel values from a window only works properly when
# visibility state Unobscured, skip if that's not so.

use 5.004;
use strict;
use Test;

my $test_count = (tests => 6538)[1];
plan tests => $test_count;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }
use MyTestImageBase;

use X11::Protocol;
use Image::Base::X11::Protocol::Window;

# uncomment this to run the ### lines
#use Devel::Comments;

my $X;
my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}

# pass display arg so as not to get a "guess" warning
if (! eval { $X = X11::Protocol->new ($display); }) {
  my $why = "Cannot connect to X server -- $@";
  foreach (1 .. $test_count) {
    skip ($why, 1, 1);
  }
  exit 0;
}

my $width = 21;
my $height = 10;
my $border = 5;

my $under_win = $X->new_rsrc;
$X->CreateWindow ($under_win, $X->root,
                  'InputOutput',
                  $X->root_depth,
                  'CopyFromParent',
                  0,0,
                  $width+$border*2, $height+$border*2,
                  $border,
                  background_pixel => $X->{'white_pixel'},
                  border_pixel => $X->{'black_pixel'},
                  override_redirect => 1,
                  colormap => 'CopyFromParent',
                 );
$X->MapWindow ($under_win);

my $win = $X->new_rsrc;
my $event_mask = $X->pack_event_mask('VisibilityChange',
                                     'PointerMotion',
                                     'ButtonPress');
my $visibility = 'no VisibilityNotify event seen';
$X->{'event_handler'} = sub {
  my (%event) = @_;
  MyTestHelpers::diag("event ",$event{'name'});
  if ($event{'name'} eq 'VisibilityNotify') {
    $visibility = $event{'state'};
    $MyTestImageBase::skip = ($visibility eq 'Unobscured'
                            ? undef
                            : "window not visible: $visibility");
    MyTestHelpers::diag ("  visibility now ", $event{'state'});
    MyTestHelpers::diag ("  skip now ", $MyTestImageBase::skip);
  }
};

# use IO::Select;
# sub X_handle_input_nonblock {
#   my ($X) = @_;
#   $X->flush;
#   my $sel = ($X->{__PACKAGE__.'.sel'}
#              ||= IO::Select->new($X->{'connection'}->fh));
#   while ($sel->can_read) {
#     MyTestHelpers::diag ("handle_input()");
#     $X->handle_input;
#   }
# }
$MyTestImageBase::handle_input = sub {
  $X->QueryPointer($X->{'root'});  # sync
};

$X->CreateWindow($win, $under_win,
                 'InputOutput',
                 $X->root_depth,
                 'CopyFromParent',
                 0,0,
                 $width,$height,
                 $border,
                 background_pixel => $X->{'black_pixel'},
                 border_pixel => $X->{'white_pixel'},
                 override_redirect => 1,
                 colormap => 'CopyFromParent',
                 event_mask => $event_mask,
                );
$X->MapWindow ($win);
my %win_attrs = $X->GetWindowAttributes ($win);

my $image = Image::Base::X11::Protocol::Window->new
  (-X => $X,
   -window => $win);

MyTestImageBase::check_image ($image);
MyTestImageBase::check_diamond ($image);

# 6526-3262=3264
if (! $X->init_extension('SHAPE')) {
  MyTestHelpers::diag ('SHAPE extension not available');
  foreach (1 .. 3264) {
    skip ('SHAPE extension not available', 1, 1);
  }
} else {
  my $image_clear_func = sub {
    $X->ShapeRectangles ($win,
                         'Bounding',
                         'Set',
                         0,0, # offset
                         'YXBanded',
                         [ 0,0, $width,$height ]);
    $X->ClearArea($win, 0,0, 0,0, 0);
  };
  &$image_clear_func();

  $image->rectangle (0,0, $width-1,$height-1, '#000000', 0);
  $image->xy(0,0, 'None');
  ok ($image->xy(0,0), 'None', 'xy() pixel None');
  ok ($image->xy(1,1) ne 'None', 1, 'xy() pixel not None');
  &$image_clear_func();

  local $MyTestImageBase::white = 'None';
  MyTestImageBase::check_image ($image, image_clear_func => $image_clear_func);
  MyTestImageBase::check_diamond ($image, image_clear_func=>$image_clear_func);
}

exit 0;
