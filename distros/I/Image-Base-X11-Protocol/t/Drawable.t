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

use 5.004;
use strict;
use Test;
use X11::Protocol;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = (tests => 6068)[1];
plan tests => $test_count;

my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  MyTestHelpers::diag ('No DISPLAY set');
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}
MyTestHelpers::diag ("DISPLAY $display");

# pass display arg so as not to get a "guess" warning
my $X;
if (! eval { $X = X11::Protocol->new ($display); }) {
  MyTestHelpers::diag ("Cannot connect to X server -- $@");
  foreach (1 .. $test_count) {
    skip ("Cannot connect to X server", 1, 1);
  }
  exit 0;
}
$X->QueryPointer($X->{'root'});  # sync

require Image::Base::X11::Protocol::Window;
MyTestHelpers::diag ("Image::Base version ", Image::Base->VERSION);

# uncomment this to run the ### lines
#use Smart::Comments;

MyTestHelpers::X11_server_info($X);
# screen number integer 0, 1, etc
my $X_screen_number = MyTestHelpers::X11_chosen_screen_number($X);


#------------------------------------------------------------------------------
# VERSION

my $want_version = 15;
ok ($Image::Base::X11::Protocol::Drawable::VERSION,
    $want_version, 'VERSION variable');
ok (Image::Base::X11::Protocol::Drawable->VERSION,
    $want_version, 'VERSION class method');

ok (eval { Image::Base::X11::Protocol::Drawable->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Image::Base::X11::Protocol::Drawable->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# root window info

{
  my $num_screens = scalar(@{$X->{'screens'}});
  my $check_screen = $num_screens - 1;
  my $check_screen_info = $X->{'screens'}->[$check_screen];
  MyTestHelpers::diag "use screen number $check_screen for checking";

  my $image = Image::Base::X11::Protocol::Drawable->new
    (-X => $X,
     -drawable => $X->{'screens'}->[$check_screen]->{'root'});
  ok ($image && $image->isa('Image::Base') && 1,
      1);
  ok ($image && $image->isa('Image::Base::X11::Protocol::Drawable') && 1,
      1);

  ok ($image->VERSION,  $want_version, 'VERSION object method');
  ok (eval { $image->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $image->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");

  ok ($image->get('-width') >= 1, 1, 'get() -width');
  ok ($image->get('-width'), $check_screen_info->{'width_in_pixels'},
      'get() -width');

  ok ($image->get('-height') >= 1, 1, 'get() -height');
  ok ($image->get('-height'), $check_screen_info->{'height_in_pixels'},
      'get() -height');

  ok ($image->get('-depth') >= 1, 1, 'get() -depth');
  ok ($image->get('-depth'), $check_screen_info->{'root_depth'},
      'get() -depth');

  ok ($image->get('-screen') >= 0, 1, 'get() -screen');
  ok ($image->get('-screen'), $check_screen, 'get() -screen');

  # no default in the Drawable class
  ok ($image->get('-colormap'), undef, 'get() -colormap');
}

#------------------------------------------------------------------------------
# bitmap
{
  my $check_screen = 0;
  my $rootwin = $X->{'screens'}->[$check_screen]->{'root'};

  my $bitmap = $X->new_rsrc;
  $X->CreatePixmap ($bitmap,
                    $rootwin,
                    1,  # depth
                    21, 10);

  my $image = Image::Base::X11::Protocol::Drawable->new
    (-X => $X,
     -drawable => $bitmap);

  ok ($image->get('-width'),  21, 'bitmap get() -width');
  ok ($image->get('-height'), 10, 'bitmap get() -height');
  ok ($image->get('-depth'),   1, 'bitmap get() -depth');
  ok ($image->get('-screen'),  0, 'bitmap get() -screen');

  MyTestHelpers::diag "MyTestImageBase on bitmap";
  require MyTestImageBase;
  local $MyTestImageBase::white = 1;
  local $MyTestImageBase::black = 0;
  MyTestImageBase::check_image ($image);

  $X->FreePixmap ($bitmap);
  $X->QueryPointer($X->{'root'});  # sync
}

{
  my $rootwin = $X->{'root'};

  my $bitmap = $X->new_rsrc;
  $X->CreatePixmap ($bitmap,
                    $rootwin,
                    1,  # depth
                    21, 10);

  my $image = Image::Base::X11::Protocol::Drawable->new
    (-X => $X,
     -drawable => $bitmap);

  my $colour = $image->xy(0,0);
  ok ($image->{'-depth'},    1, 'xy() sets -depth');
  ok ($image->get('-depth'), 1, 'bitmap get() -depth');

  $X->FreePixmap ($bitmap);
  $X->QueryPointer($X->{'root'});  # sync
}

#------------------------------------------------------------------------------
# pixmap

{
  my $pixmap = $X->new_rsrc;
  $X->CreatePixmap ($pixmap,
                    $X->{'root'},
                    $X->{'root_depth'},
                    21, 10);

  my $image = Image::Base::X11::Protocol::Drawable->new
    (-X => $X,
     -drawable => $pixmap);
  ok ($image && $image->isa('Image::Base') && 1,
 1);
  ok ($image && $image->isa('Image::Base::X11::Protocol::Drawable') && 1,
 1);

  ok ($image->VERSION,  $want_version, 'VERSION object method');
  ok (eval { $image->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $image->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");

  ok ($image->get('-width'),  21, 'get() -width');
  ok ($image->get('-height'), 10, 'get() -height');
  ok ($image->get('-depth'),  $X->{'root_depth'}, 'get() -depth');

  ok ($image->get('-screen'), $X_screen_number, 'get() -screen_number');
  ok ($image->get('-colormap'), undef, 'get() -colormap');

  #
  # add_colours
  #

  MyTestHelpers::diag "add_colours()";
  $image->set('-colormap', $X->{'default_colormap'});
  $image->add_colours('black', 'white', '#FF00FF', '#00ff00', '#0000AAAAbbbb');

  #
  # line
  #
  $image->rectangle (0,0, 19,9, 'black', 1);
  $image->line (5,5, 7,7, 'white', 0);
  ok ($image->xy (4,4), 'black');
  ok ($image->xy (5,5), 'white');
  ok ($image->xy (5,6), 'black');
  ok ($image->xy (6,6), 'white');
  ok ($image->xy (7,7), 'white');
  ok ($image->xy (8,8), 'black');

  $image->rectangle (0,0, 19,9, 'black', 1);
  $image->line (0,0, 2,2, 'white', 1);
  ok ($image->xy (0,0), 'white');
  ok ($image->xy (1,1), 'white');
  ok ($image->xy (2,1), 'black');
  ok ($image->xy (3,3), 'black');

  #
  # xy
  #

  $image->xy (2,2, 'black');
  $image->xy (3,3, 'white');
  ok ($image->xy (2,2), 'black', 'xy()  ');
  ok ($image->xy (3,3), 'white', 'xy() *');

  #
  # rectangle
  #

  # hollow
  $image->rectangle (0,0, 19,9, 'black', 1);
  $image->rectangle (5,5, 7,7, 'white', 0);
  ok ($image->xy (5,5), 'white');
  ok ($image->xy (5,6), 'white');
  ok ($image->xy (5,7), 'white');

  ok ($image->xy (6,5), 'white');
  ok ($image->xy (6,6), 'black');
  ok ($image->xy (6,7), 'white');

  ok ($image->xy (7,5), 'white');
  ok ($image->xy (7,6), 'white');
  ok ($image->xy (7,7), 'white');

  ok ($image->xy (8,8), 'black');
  #


  # filled
  $image->rectangle (0,0, 19,9, 'black', 1);
  $image->rectangle (5,5, 7,7, 'white', 1);
  ok ($image->xy (5,5), 'white');
  ok ($image->xy (5,6), 'white');
  ok ($image->xy (5,7), 'white');

  ok ($image->xy (6,5), 'white');
  ok ($image->xy (6,6), 'white');
  ok ($image->xy (6,7), 'white');

  ok ($image->xy (7,5), 'white');
  ok ($image->xy (7,6), 'white');
  ok ($image->xy (7,7), 'white');

  ok ($image->xy (8,8), 'black');
  #

  MyTestHelpers::diag "MyTestImageBase on pixmap depth=$X->{'root_depth'}";
  require MyTestImageBase;
  local $MyTestImageBase::white = 'white';
  local $MyTestImageBase::black = 'black';
  MyTestImageBase::check_diamond ($image);
  MyTestImageBase::check_image ($image);

  $X->FreePixmap ($pixmap);
  $X->QueryPointer($X->{'root'});  # sync
  ok (1, 1, 'successful destroy and sync');
}

#------------------------------------------------------------------------------
# add_colours()

sub step_seq_num {
  my ($X) = @_;
  my $seq = $X->send('QueryPointer',$X->{'root'});
  my $reply;
  $X->add_reply ($seq, \$reply);
  $X->handle_input_for($seq);
  $X->delete_reply ($seq);
  return $seq;
}

sub run_seq_to_FFA0 {
  my ($X) = @_;
  my $target = 0xFFA0;
  my $limit = 100;
  my $count = 0;
  my $seq = step_seq_num($X);

  for (;;) {
    my $diff = ($target - $seq) & 0xFFFF;
    ### $diff
    if ($diff < 10) {
      MyTestHelpers::diag "run_seq_to_FFA0() $count steps to seq $seq";
      last;
    }
    my @pending;
    for (;;) {
      last if ($diff < 10 || @pending > 2048);
      $seq = $X->send('QueryPointer',$X->{'root'});
      push @pending, $seq;
      my $reply;
      $X->add_reply ($seq, \$reply);
      $count++;
      $diff--;
    }
    $X->handle_input_for($seq);
    foreach my $pending (@pending) {
      $X->delete_reply ($pending);
    }
    if (--$limit < 0) {
      MyTestHelpers::diag "run_seq_to_FFA0(): oops, cannot get seq to 0xFFA0";
      die;
    }
  }
}

my $rgb = 2;
sub next_test_colour {
  return sprintf('#%06X',$rgb++);
}

{
  my $depth = $X->{'root_depth'};
  my $colormap = $X->{'default_colormap'};
  my $num_test_colours = int ((2 ** $depth) / 3);
  if ($num_test_colours > 5000) {
    $num_test_colours = 5000;
  }

  my $pixmap = $X->new_rsrc;
  $X->CreatePixmap ($pixmap,
                    $X->{'root'},
                    $depth,
                    21, 10);
  my $image = Image::Base::X11::Protocol::Drawable->new
    (-X => $X,
     -drawable => $pixmap,
     -colormap => $colormap);

  {
    MyTestHelpers::diag "add_colours() check for error received";
    my $error_seen = 0;
    local $X->{'error_handler'} = sub {
      $error_seen = 1;
    };
    $X->send('QueryPointer',0);

    my $colour = next_test_colour();
    $image->add_colours($colour);
    ok ($error_seen, 1, 'add_colours() with pending error - error handled');
    ok (defined $image->{'-colour_to_pixel'}->{$colour},
        1,
        'add_colours() with pending error - colour allocated');
  }

  {
    my @colours = map {next_test_colour()} 1 .. $num_test_colours;
    MyTestHelpers::diag "add_colours() ",scalar(@colours);
    $image->add_colours(@colours);
  }
  {
    my @colours = map {next_test_colour()} 1 .. $num_test_colours;
    MyTestHelpers::diag "add_colours() ",scalar(@colours)," with seq wraparound";
    run_seq_to_FFA0($X);
    $image->add_colours(@colours);
  }

  $X->FreePixmap ($pixmap);
  $X->QueryPointer($X->{'root'});  # sync
  ok (1, 1, 'successful destroy and sync');
}


exit 0;
