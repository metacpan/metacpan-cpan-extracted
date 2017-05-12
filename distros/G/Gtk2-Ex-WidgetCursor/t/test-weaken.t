#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetCursor.
#
# Gtk2-Ex-WidgetCursor is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-WidgetCursor is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetCursor.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2::Ex::WidgetCursor;

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => "due to no DISPLAY available";

# Test::Weaken 2.002 for "ignore"
eval "use Test::Weaken 2.002;
      use Test::Weaken::Gtk2;
      1"
  or plan skip_all => "due to Test::Weaken 2.002 and/or Test::Weaken::Gtk2 not available -- $@";
diag ("Test::Weaken version ", Test::Weaken->VERSION);

plan tests => 3;

require Gtk2;
MyTestHelpers::glib_gtk_versions();


#-----------------------------------------------------------------------------

# sub my_ignore {
#   my ($ref) = @_;
#   return (Test::Weaken::ExtraBits::ignore_global_function($ref)
#           || Test::Weaken::Gtk2::ignore_default_display($ref));
# }

{
  my $leaks = Test::Weaken::leaks (sub { Gtk2::Ex::WidgetCursor->new });
  is ($leaks, undef, 'empty');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain($leaks);
  }
}

{
  my $leaks = Test::Weaken::leaks
    (sub {
       my $drawing = Gtk2::DrawingArea->new;
       my $wcursor = Gtk2::Ex::WidgetCursor->new (widget => $drawing);
       return [ $wcursor, $drawing ];
     });
  is ($leaks, undef, 'with draw, unrealized and inactive');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain($leaks);
  }
}

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $toplevel = Gtk2::Window->new ('toplevel');
         $toplevel->show;
         my $wcursor = Gtk2::Ex::WidgetCursor->new (widget => $toplevel,
                                                    active => 1);
         MyTestHelpers::main_iterations();
         return [ $toplevel, $wcursor ];
       },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
     });
  is ($leaks, undef, 'toplevel, shown and active');
  if ($leaks && defined &explain) {
    diag "Test-Weaken ", explain($leaks);
  }
}

exit 0;
