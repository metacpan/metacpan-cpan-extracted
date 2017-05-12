#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Gtk2-Ex-Dashes.
#
# Gtk2-Ex-Dashes is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Dashes is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Dashes.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Test::More tests => 14;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2::Ex::Dashes::MenuItem;

my $want_version = 2;
my $check_version = $want_version + 1000;
{
  is ($Gtk2::Ex::Dashes::MenuItem::VERSION, $want_version,
      'VERSION variable');
  is (Gtk2::Ex::Dashes::MenuItem->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Gtk2::Ex::Dashes::MenuItem->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  ok (! eval { Gtk2::Ex::Dashes::MenuItem->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
MyTestHelpers::glib_gtk_versions();

{
  my $item = Gtk2::Ex::Dashes::MenuItem->new;
  is ($item->VERSION, $want_version, 'VERSION object method');
  ok (eval { $item->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $item->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

#-----------------------------------------------------------------------------
# set_direction

{
  my $item = Gtk2::Ex::Dashes::MenuItem->new;
  my $dashes = $item->get_child;
  is ($item->get_direction, $dashes->get_direction,
      'direction same initially');

  foreach my $dir ('ltr', 'rtl') {
    $item->set_direction ($dir);
    is ($item->get_direction, $dashes->get_direction,
        "'direction same on set $dir");
  }
}

#-----------------------------------------------------------------------------

Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
my $have_display = Gtk2->init_check;

#-----------------------------------------------------------------------------
# ypad from ythickness

SKIP: {
  $have_display or skip 'due to no DISPLAY available', 3;

  {
    my $item = Gtk2::Ex::Dashes::MenuItem->new;
    my $dashes = $item->get_child;
    my $yt = $dashes->style->ythickness;
    is ($dashes->get('ypad'), $yt, 'ypad initial');

    my $yt2 = $yt + 5;
    Gtk2::Rc->parse_string (<<"HERE");
style "my_style" {
  ythickness = $yt2
}
class "Gtk2__Ex__Dashes" style "my_style"
HERE

    require Gtk2::Ex::Dashes;
    my $d2 = Gtk2::Ex::Dashes->new;
    my $style2 = Gtk2::Rc->get_style ($d2);
    is ($style2->ythickness, $yt2, 'my_style ythickness');

    $dashes->set_style ($style2);
    is ($dashes->get('ypad'), $yt2, 'ypad with style2');
  }
}

#-----------------------------------------------------------------------------
# weaken()

{
  my $item = Gtk2::Ex::Dashes::MenuItem->new;
  require Scalar::Util;
  Scalar::Util::weaken ($item);
  is ($item, undef, 'garbage collect when weakened');
}

exit 0;
