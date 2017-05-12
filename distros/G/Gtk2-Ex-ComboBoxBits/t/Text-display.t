#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
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

require Gtk2::Ex::ComboBox::Text;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

plan tests => 14;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 32;
  is ($Gtk2::Ex::ComboBox::Text::VERSION,
      $want_version,
      'VERSION variable');
  is (Gtk2::Ex::ComboBox::Text->VERSION,
      $want_version,
      'VERSION class method');

  ok (eval { Gtk2::Ex::ComboBox::Text->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::ComboBox::Text->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $combo = Gtk2::Ex::ComboBox::Text->new;
  is ($combo->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $combo->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $combo->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}


#-----------------------------------------------------------------------------
# notify

{
  my $combo = Gtk2::Ex::ComboBox::Text->new (append_text => 'foo',
                                             append_text => 'bar-ski',
                                             append_text => 'quux');
  my $saw_notify;
  $combo->signal_connect
    ('notify::active-text' => sub {
       $saw_notify = $combo->get('active-text');
     });
  $combo->set (active_text => 'quux');
  is ($combo->get('active-text'), 'quux', 'get() after set()');
  is ($saw_notify, 'quux', 'notify from set("active_text")');

  $combo->set_active (0);
  is ($combo->get('active-text'), 'foo', 'get() after set_active()');
  is ($saw_notify, 'foo', 'notify from set_active()');
}


#-----------------------------------------------------------------------------
# append/prepend

{
  my $combo = Gtk2::Ex::ComboBox::Text->new;
  $combo->set (append_text => 'foo',
               prepend_text => 'bar');
  $combo->set_active (0);
  is ($combo->get_active_text, 'bar', 'prepended bar');
  $combo->set_active (1);
  is ($combo->get_active_text, 'foo', 'appended foo');
}


#-----------------------------------------------------------------------------
# weaken()

{
  my $combo = Gtk2::Ex::ComboBox::Text->new;
  require Scalar::Util;
  Scalar::Util::weaken ($combo);
  is ($combo, undef,'garbage collect when weakened');
}

exit 0;
