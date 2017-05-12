#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-WidgetBits.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;
$have_display or
  plan skip_all => 'due to no DISPLAY available';
MyTestHelpers::glib_gtk_versions();

plan tests => 7;
require Gtk2::Ex::Statusbar::Message;


#-----------------------------------------------------------------------------
{
  my $want_version = 48;
  is ($Gtk2::Ex::Statusbar::Message::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::Statusbar::Message->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Gtk2::Ex::Statusbar::Message->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::Statusbar::Message->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
# misc

{
  my $statusbar = Gtk2::Statusbar->new;
  my $msg = Gtk2::Ex::Statusbar::Message->new
    (statusbar => $statusbar,
     message   => 'hello');
  is ($msg->get('message'), 'hello');
  is ($msg->get('statusbar'), $statusbar);
  undef $statusbar;
  is ($msg->get('statusbar'), undef,
      'only weak reference held to statusbar');
}

#-----------------------------------------------------------------------------

{
  my $toplevel = Gtk2::Window->new('toplevel');
  my $statusbar = Gtk2::Statusbar->new;
  $toplevel->add($statusbar);
  $toplevel->show_all;
  MyTestHelpers::main_iterations();
  my $msg = Gtk2::Ex::Statusbar::Message->new
    (statusbar => $statusbar,
     message => 'hello');
  $msg->{'circular'} = $statusbar;
  $statusbar->{'circular'} = $msg;
}

exit 0;
