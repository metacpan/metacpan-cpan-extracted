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

use Gtk2::Ex::History::Button;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

plan tests => 9;

#-----------------------------------------------------------------------------
my $want_version = 8;
my $check_version = $want_version + 1000;
is ($Gtk2::Ex::History::Button::VERSION, $want_version, 'VERSION variable');
is (Gtk2::Ex::History::Button->VERSION,  $want_version, 'VERSION class method');
{ ok (eval { Gtk2::Ex::History::Button->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  ok (! eval { Gtk2::Ex::History::Button->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# new()
{
  my $button = Gtk2::Ex::History::Button->new;
  isa_ok ($button, 'Gtk2::Ex::History::Button');

  is ($button->VERSION, $want_version, 'VERSION object method');
  ok (eval { $button->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $button->VERSION($want_version + 1000); 1 },
      "VERSION object check " . ($want_version + 1000));

  Scalar::Util::weaken ($button);
  is ($button, undef, 'gc when weakened');
}

exit 0;
