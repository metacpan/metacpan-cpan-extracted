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

my $test_count = (tests => 14)[1];
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

require Image::Base::X11::Protocol::Pixmap;
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

my $want_version = 15;
ok ($Image::Base::X11::Protocol::Pixmap::VERSION,
    $want_version,
    'VERSION variable');
ok (Image::Base::X11::Protocol::Pixmap->VERSION,
    $want_version,
    'VERSION class method');

ok (eval { Image::Base::X11::Protocol::Pixmap->VERSION($want_version); 1 },
    1,
    "VERSION class check $want_version");
my $check_version = $want_version + 1000;
ok (! eval { Image::Base::X11::Protocol::Pixmap->VERSION($check_version); 1 },
    1,
    "VERSION class check $check_version");

#------------------------------------------------------------------------------
# new() bitmap

{
  my $rootwin = $X->{'root'};
  my %rootwin_geom = $X->GetGeometry ($rootwin);
  my %rootwin_attrs = $X->GetWindowAttributes ($rootwin);

  my $image = Image::Base::X11::Protocol::Pixmap->new
    (-X          => $X,
     -depth      => 1,
     -width      => 10,
     -height     => 10);
  my $pixmap = $image->get('-pixmap');
  ok (defined $pixmap && $pixmap > 0, 1, 'bitmap -pixmap created');

  ok ($image->get('-depth'), 1, "bitmap -depth");
  ok ($image->get('-colormap'), undef, "bitmap -colormap");

  $X->FreePixmap ($pixmap);
  $X->QueryPointer($X->{'root'});  # sync
  ok (1, 1, 'FreePixmap and sync');
}

#------------------------------------------------------------------------------
# new() for_window

{
  my $rootwin = $X->{'root'};
  my %rootwin_geom = $X->GetGeometry ($rootwin);
  my %rootwin_attrs = $X->GetWindowAttributes ($rootwin);

  my $image = Image::Base::X11::Protocol::Pixmap->new
    (-X          => $X,
     -width      => 10,
     -height     => 20,
     -for_window => $rootwin);
  my $pixmap = $image->get('-pixmap');
  ok (defined $pixmap && $pixmap > 0, 1, '-pixmap created');

  ok ($image->get('-depth'),  $rootwin_geom{'depth'}, "-depth");
  ok ($image->get('-width'),  10, "-width");
  ok ($image->get('-height'), 20, "-height");

  ok ($image->get('-colormap'),
      $rootwin_attrs{'colormap'},
      "-colormap default from root window attributes");

  $X->FreePixmap ($pixmap);
  $X->QueryPointer($X->{'root'});  # sync
  ok (1, 1, 'FreePixmap and sync');
}

exit 0;
