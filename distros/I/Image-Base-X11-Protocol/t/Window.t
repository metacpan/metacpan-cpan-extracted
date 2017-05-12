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

my $test_count = (tests => 6)[1];
plan tests => $test_count;

my $display = $ENV{'DISPLAY'};
if (! defined $display) {
  foreach (1 .. $test_count) {
    skip ('No DISPLAY set', 1, 1);
  }
  exit 0;
}

# pass display arg so as not to get a "guess" warning
my $X;
if (! eval { $X = X11::Protocol->new ($display); }) {
  my $why = "Cannot connect to X server -- $@";
  foreach (1 .. $test_count) {
    skip ($why, 1, 1);
  }
  exit 0;
}
$X->QueryPointer($X->{'root'});  # sync

require Image::Base::X11::Protocol::Window;
MyTestHelpers::diag ("Image::Base version ", Image::Base->VERSION);

# screen number integer 0, 1, etc
sub X_chosen_screen_number {
  my ($X) = @_;
  foreach my $i (0 .. $#{$X->{'screens'}}) {
    if ($X->{'screens'}->[$i]->{'root'} == $X->{'root'}) {
      return $i;
    }
  }
  die "Oops, current screen not found";
}
my $X_screen_number = X_chosen_screen_number($X);

#------------------------------------------------------------------------------
# VERSION

my $want_version = 14;
ok ($Image::Base::X11::Protocol::Window::VERSION,
    $want_version,
    'VERSION variable');
ok (Image::Base::X11::Protocol::Window->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { Image::Base::X11::Protocol::Window->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Image::Base::X11::Protocol::Window->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# new()

{
  my $win = $X->new_rsrc;
  $X->CreateWindow($win, $X->root,
                   'InputOutput',
                   $X->root_depth,
                   'CopyFromParent',
                   0,0,
                   100,100,
                   5,   # border
                   background_pixel => 0x123456, # $X->{'white_pixel'},
                   override_redirect => 1,
                   colormap => 'CopyFromParent',
                  );
  $X->MapWindow ($win);
  my %win_attrs = $X->GetWindowAttributes ($win);

  my $image = Image::Base::X11::Protocol::Window->new
    (-X => $X,
     -window => $win);

  ok ($image->get('-colormap'),
      $win_attrs{'colormap'},
      "-colormap default from window attributes");

  $X->DestroyWindow ($win);
  $X->QueryPointer($X->{'root'});  # sync
  ok (1, 1, 'successful destroy and sync');
}

exit 0;
