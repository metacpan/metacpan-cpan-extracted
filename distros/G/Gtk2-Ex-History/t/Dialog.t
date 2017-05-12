#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-History.
#
# Gtk2-Ex-History is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-History is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-History.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2::Ex::History::Dialog;

require Gtk2;
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

plan tests => 13;

#-----------------------------------------------------------------------------
my $want_version = 8;
my $check_version = $want_version + 1000;
is ($Gtk2::Ex::History::Dialog::VERSION, $want_version, 'VERSION variable');
is (Gtk2::Ex::History::Dialog->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { Gtk2::Ex::History::Dialog->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  ok (! eval { Gtk2::Ex::History::Dialog->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# new()
{
  my $dialog = Gtk2::Ex::History::Dialog->new;
  isa_ok ($dialog, 'Gtk2::Ex::History::Dialog', 'new()');

  is ($dialog->VERSION, $want_version, 'VERSION object method');
  ok (eval { $dialog->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $dialog->VERSION($want_version + 1000); 1 },
      "VERSION object check " . ($want_version + 1000));

  $dialog->destroy;
  Scalar::Util::weaken ($dialog);
  is ($dialog, undef, 'new() gc when weakened');
}

#------------------------------------------------------------------------------
# present() with no history set

{
  my $dialog = Gtk2::Ex::History::Dialog->new;
  $dialog->present;
  MyTestHelpers::wait_for_event($dialog,'map-event');
  $dialog->destroy;
}

#------------------------------------------------------------------------------
# popup()

{
  my $history = Gtk2::Ex::History->new;
  my $dialog = Gtk2::Ex::History::Dialog->popup ($history);
  isa_ok ($dialog, 'Gtk2::Ex::History::Dialog',
         'popup without history');
  MyTestHelpers::wait_for_event($dialog,'map-event');

  $dialog->destroy;
  Scalar::Util::weaken ($dialog);
  is ($dialog, undef, 'popup() gc when weakened');
}
{
  my $parent = Gtk2::Window->new('toplevel');
  my $history = Gtk2::Ex::History->new;
  my $dialog = Gtk2::Ex::History::Dialog->popup ($history, $parent);
  isa_ok ($dialog, 'Gtk2::Ex::History::Dialog',
         'popup with history');
  MyTestHelpers::wait_for_event($dialog,'map-event');
  $parent->destroy;
  $dialog->destroy;
  Scalar::Util::weaken ($dialog);
  is ($dialog, undef, 'popup() with history, gc when weakened');
}

exit 0;
