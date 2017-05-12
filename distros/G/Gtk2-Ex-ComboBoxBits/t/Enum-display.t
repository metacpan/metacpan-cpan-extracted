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


# Tests of Gtk2::Ex::ComboBox::Enum requiring a DISPLAY.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::ComboBox::Enum;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';

plan tests => 13;

MyTestHelpers::glib_gtk_versions();
Glib::Type->register_enum ('My::Test1', 'foo', 'bar-ski', 'quux');

#------------------------------------------------------------------------------
# enum-type

{
  my $combo = Gtk2::Ex::ComboBox::Enum->new;
  is ($combo->get ('enum-type'), undef,
     'enum-type default undef');

  my $pspec = $combo->find_property('enum-type');
  my $default = $pspec->get_default_value;
  if (defined $default) {
    $default = "'$default'";
  }
  diag "enum-type paramspec class: ", ref($pspec);
  diag "enum-type get_default_value: ", $default;
}

#------------------------------------------------------------------------------
# active-nick

{
  my $combo = Gtk2::Ex::ComboBox::Enum->new;
  is ($combo->get ('active-nick'), undef,
      'active-nick default undef');
  is ($combo->get_active_nick, undef,
      'get_active_nick() default undef');

  $combo->set_active_nick (undef);

 SKIP: {
    eval{Glib->VERSION(1.240);1}
      or skip 'no Glib::ParamSpec->string default undef until glib 1.240', 1;

    my $pspec = $combo->find_property('active-nick');
    is ($pspec->get_default_value, undef,
        'active-nick pspec get_default_value');
  }
}

#-----------------------------------------------------------------------------
# notify

{
  my $combo = Gtk2::Ex::ComboBox::Enum->new (enum_type => 'My::Test1');
  my $saw_notify;
  $combo->signal_connect
    ('notify::active-nick' => sub {
       $saw_notify = $combo->get('active-nick');
     });

  undef $saw_notify;
  $combo->set (active_nick => 'quux');
  is ($combo->get('active-nick'), 'quux', 'get() after set()');
  is ($combo->get_active_nick, 'quux', 'get_active_nick() after set()');
  is ($saw_notify, 'quux', 'notify from set("active_nick")');

  undef $saw_notify;
  $combo->set_active (0);
  is ($combo->get('active-nick'), 'foo', 'get() after set_active()');
  is ($combo->get_active_nick, 'foo', 'get_active_nick() after set_active()');
  is ($saw_notify, 'foo', 'notify from set_active()');

  undef $saw_notify;
  $combo->set_active (0);
  is ($saw_notify, undef, 'no notify from set_active() unchanged');

  undef $saw_notify;
  $combo->set_active_nick ('foo');
  is ($saw_notify, undef, 'no notify from set_active_nick() unchanged');
}

#-----------------------------------------------------------------------------
# Scalar::Util::weaken

{
  my $combo = Gtk2::Ex::ComboBox::Enum->new;
  require Scalar::Util;
  Scalar::Util::weaken ($combo);
  is ($combo, undef,'garbage collect when weakened');
}

exit 0;
