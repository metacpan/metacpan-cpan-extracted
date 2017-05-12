#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Splash.
#
# Gtk2-Ex-Splash is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Splash is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Splash.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
MyTestHelpers::glib_gtk_versions();

# Test::Weaken 3 for "contents"
eval "use Test::Weaken 3; 1"
  or plan skip_all => "Test::Weaken 3 not available -- $@";

eval "use Test::Weaken::Gtk2; 1"
  or plan skip_all => "Test::Weaken::Gtk2 not available -- $@";

plan tests => 2;

require Gtk2::Ex::Splash;

#-----------------------------------------------------------------------------
# Test::Weaken

require Test::Weaken::ExtraBits;

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         return Gtk2::Ex::Splash->new;
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
     });
  is ($leaks, undef, 'gc from new()');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $splash = Gtk2::Ex::Splash->new;
         $splash->show;
         return $splash;
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => \&Test::Weaken::Gtk2::contents_container,
       # ignore => \&my_ignore,
     });
  is ($leaks, undef, 'gc while show()');
  MyTestHelpers::test_weaken_show_leaks($leaks);
}

exit 0;
