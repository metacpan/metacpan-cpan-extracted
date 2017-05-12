#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2;
BEGIN {
  Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
  Gtk2->init_check
    or plan skip_all => 'due to no DISPLAY available';

  plan tests => 12;
}
require Gtk2::Ex::ComboBox::PixbufType;


#------------------------------------------------------------------------------
# VERSION

my $want_version = 32;
{
  is ($Gtk2::Ex::ComboBox::PixbufType::VERSION,
      $want_version,
      'VERSION variable');
  is (Gtk2::Ex::ComboBox::PixbufType->VERSION,
      $want_version,
      'VERSION class method');

  ok (eval { Gtk2::Ex::ComboBox::PixbufType->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::ComboBox::PixbufType->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $combo = Gtk2::Ex::ComboBox::PixbufType->new;
  is ($combo->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $combo->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $combo->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}


#-----------------------------------------------------------------------------
# for-width, for-height

{
  my $combo = Gtk2::Ex::ComboBox::PixbufType->new;
  is ($combo->get('for-width'),  0, 'for-width  initial');
  is ($combo->get('for-height'), 0, 'for-height initial');
}


#-----------------------------------------------------------------------------
# notify

{
  my $combo = Gtk2::Ex::ComboBox::PixbufType->new;
  my $saw_notify;
  $combo->signal_connect
    ('notify::active-type' => sub {
       $saw_notify = $combo->get('active-type');
     });
  $combo->set (active_type => 'jpeg');
  is ($combo->get('active-type'), 'jpeg', 'get() after set()');
  is ($saw_notify, 'jpeg', 'notify from set("active_type")');

#   $combo->set_active (0);
#   is ($combo->get('active-type'), 'png', 'get() after set_active()');
#   is ($saw_notify, 'png', 'notify from set_active()');
}


#-----------------------------------------------------------------------------
# Scalar::Util::weaken

{
  my $combo = Gtk2::Ex::ComboBox::PixbufType->new;
  require Scalar::Util;
  Scalar::Util::weaken ($combo);
  is ($combo, undef,
      'garbage collect when weakened');
}

exit 0;
