#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Image-Base-Gtk2.
#
# Image-Base-Gtk2 is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Gtk2 is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Gtk2.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use Test::More;
use Image::Base::Gtk2::Gdk::Image;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

eval { Gtk2->VERSION(1.240); 1 }
  or plan skip_all => 'due to Gtk2-Perl '.Gtk2->VERSION.', no full GdkImage until 1.240';

eval "use Test::Weaken 2.000; 1"
  or plan skip_all => "due to Test::Weaken 2.000 not available -- $@";
diag ("Test::Weaken version ", Test::Weaken->VERSION);

plan tests => 1;

{
  my $leaks = Test::Weaken::leaks
    (sub { return Image::Base::Gtk2::Gdk::Image->new
             (-width => 6, -height => 7) });
  is ($leaks, undef, 'deep garbage collection');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
