#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-DateSpinner.
#
# Gtk2-Ex-DateSpinner is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-DateSpinner is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-DateSpinner.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2::Ex::DateSpinner;
use Gtk2::Ex::DateSpinner::PopupForEntry;
use Gtk2::Ex::DateSpinner::CellRenderer;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

BEGIN {
  # seem to need a DISPLAY initialized in gtk 2.16 or get a slew of warnings
  # creating a Gtk2::Ex::DateSpinner
  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
  Gtk2->init_check
    or plan skip_all => "due to no DISPLAY available";

  # Test::Weaken 3 for "contents"
  eval "use Test::Weaken 3; 1"
    or plan skip_all => "due to Test::Weaken 3 not available -- $@";
  diag ("Test::Weaken version ", Test::Weaken->VERSION);

  eval "use Test::Weaken::Gtk2; 1"
    or plan skip_all => "due to Test::Weaken::Gtk2 not available -- $@";

  plan tests => 5;
}

require Gtk2;
MyTestHelpers::glib_gtk_versions();

#------------------------------------------------------------------------------
# DateSpinner

diag "DateSpinner";
{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub { return Gtk2::Ex::DateSpinner->new },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'DateSpinner deep garbage collection');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

#------------------------------------------------------------------------------
# DateSpinner::PopupForEntry

diag "PopupForEntry";

{
  my $leaks = Test::Weaken::leaks
    ({ constructor => sub { Gtk2::Ex::DateSpinner::PopupForEntry->new },
       destructor => \&Test::Weaken::Gtk2::destructor_destroy,
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'PopupForEntry garbage collection');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

#------------------------------------------------------------------------------
# DateSpinner::CellRenderer

{
  my $leaks = Test::Weaken::leaks
    (sub { Gtk2::Ex::DateSpinner::CellRenderer->new });
  is ($leaks, undef, 'CellRenderer garbage collection');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }
}

{
  my $toplevel = Gtk2::Window->new ('toplevel');
  my $renderer = Gtk2::Ex::DateSpinner::CellRenderer->new (editable => 1);

  my $leaks = Test::Weaken::leaks
    ({ constructor => sub {
         my $event = Gtk2::Gdk::Event->new ('button-press');
         my $rect = Gtk2::Gdk::Rectangle->new (0, 0, 100, 100);
         my $editable = $renderer->start_editing
           ($event, $toplevel, "0", $rect, $rect, ['selected']);
         isa_ok ($editable, 'Gtk2::CellEditable', 'start_editing return');
         $toplevel->add ($editable);
         return $editable;
       },
       destructor => sub {
         my ($editable) = @_;
         $toplevel->remove ($editable);
         # iterate for idle handler hack for Gtk2 1.202
         MyTestHelpers::main_iterations();
       },
       contents => \&Test::Weaken::Gtk2::contents_container,
     });
  is ($leaks, undef, 'CellRenderer garbage collection -- after start_editing');
  if ($leaks) {
    eval { diag "Test-Weaken ", explain($leaks) }; # explain in Test::More 0.82
  }

  $toplevel->destroy;
}


exit 0;
