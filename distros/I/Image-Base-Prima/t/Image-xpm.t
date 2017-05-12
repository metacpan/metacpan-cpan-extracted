#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-Prima.
#
# Image-Base-Prima is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Prima is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Prima.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

use Prima::noX11; # without connecting to the server
use Prima;

my $test_count = (tests => 12)[1];
plan tests => $test_count;

{
  my $d = Prima::Image->new;
  my $codecs = $d->codecs;
  MyTestHelpers::diag ("codecs: ",
                       join(' ',map {$_->{'fileShortType'}} @$codecs));

  my $have_xpm = 0;
  foreach my $codec (@$codecs) {
    if ($codec->{'fileShortType'} eq 'XPM') {
      $have_xpm = 1;
    }
  }
  if (! $have_xpm) {
    foreach (1 .. $test_count) {
      skip ('due to no XPM codec', 1, 1);
    }
    exit 0;
  }
}

require Image::Base::Prima::Image;

my $filename = 'tempfile.xpm';
MyTestHelpers::diag ("Tempfile ", $filename);
unlink $filename;
ok (! -e $filename, 1, "removed any existing $filename");
END {
  if (defined $filename) {
    MyTestHelpers::diag ("Remove tempfile ",$filename);
    unlink $filename
      or MyTestHelpers::diag ("Oops, cannot remove $filename: $!");
  }
}

#------------------------------------------------------------------------------
# save() / load()

{
  my $image = Image::Base::Prima::Image->new (-width => 10,
                                              -height => 11,
                                              -hotx => 5,
                                              -hoty => 6);
  ok ($image->get('-drawable')->{'extras'}->{'hotSpotX'}, 5);
  ok ($image->get('-drawable')->{'extras'}->{'hotSpotY'}, 6);
  $image->save ($filename);
  ok (-e $filename, 1, "save() to $filename");
}
{
  my $image = Image::Base::Prima::Image->new (-file => $filename);
  ok ($image->get('-file_format'), 'XPM',
      'load() -file_format');
  ok ($image->get('-width'), 10,
      'load() -width');
  ok ($image->get('-height'), 11,
      'load() -height');
  ok ($image->get('-hotx'), 5,
      'load() -hotx');
  ok ($image->get('-hoty'), 6,
      'load() -hoty');
}

#------------------------------------------------------------------------------
# as undef

{
  my $image = Image::Base::Prima::Image->new (-width => 10,
                                              -height => 11);
  $image->set (-hotx => 5,
               -hoty => 6);
  $image->set (-hotx => undef,
               -hoty => undef);
  $image->save ($filename);
  ok (-e $filename, 1, "save() to $filename");
}
{
  my $image = Image::Base::Prima::Image->new (-file => $filename);
  ok ($image->get('-hotx'), undef,
      'load() -hotx');
  ok ($image->get('-hoty'), undef,
      'load() -hoty');
}

exit 0;
