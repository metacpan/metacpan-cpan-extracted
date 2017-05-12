#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-NoShrink.
#
# Gtk2-Ex-NoShrink is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-NoShrink is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NoShrink.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More;

# Test::Weaken 3 for "contents"
BEGIN {
  my $have_test_weaken = eval "use Test::Weaken 3;
                               use Test::Weaken::Gtk2;
                               1";
  if (! $have_test_weaken) {
    plan skip_all => "due to Test::Weaken 3 and/or Test::Weaken::Gtk2 not available -- $@";
  }
  diag ("Test::Weaken version ", Test::Weaken->VERSION);

  plan tests => 3;

 SKIP: { eval 'use Test::NoWarnings; 1'
           or skip 'Test::NoWarnings not available', 1; }
}

use Gtk2::Ex::NoShrink;
use lib 't';
use MyTestHelpers;

require Gtk2;
MyTestHelpers::glib_gtk_versions();

#------------------------------------------------------------------------------

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub { return Gtk2::Ex::NoShrink->new },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'deep garbage collection');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain $leaks;
  }
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $label = Gtk2::Label->new ('hello');
         my $noshrink = Gtk2::Ex::NoShrink->new (child => $label);
         return [ $noshrink, $label ];
       },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'with a Label child widget');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain $leaks;
  }
}

exit 0;
