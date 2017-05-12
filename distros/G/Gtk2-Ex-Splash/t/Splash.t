#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-Splash.
#
# Gtk2-Ex-Splash is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-Splash is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-Splash.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
MyTestHelpers::glib_gtk_versions();

plan tests => 8;

require Gtk2::Ex::Splash;

#------------------------------------------------------------------------------
# properties

diag "properties:";
{
  my %super;
  foreach my $pspec (Gtk2::Window->list_properties) {
    $super{$pspec->get_name} = 1;
  }
  foreach my $pspec (Gtk2::Ex::Splash->list_properties) {
    my $pname = $pspec->get_name;
    next if $super{$pname};
    diag sprintf "  %-10s %s\n", $pname, $pspec->get_nick;
  }
}

#------------------------------------------------------------------------------
# VERSION

my $want_version = 52;
{
  is ($Gtk2::Ex::Splash::VERSION,
      $want_version,
      'VERSION variable');
  is (Gtk2::Ex::Splash->VERSION,
      $want_version,
      'VERSION class method');

  ok (eval { Gtk2::Ex::Splash->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::Splash->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $splash = Gtk2::Ex::Splash->new;
  is ($splash->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $splash->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $splash->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}


#-----------------------------------------------------------------------------
# Scalar::Util::weaken

{
  my $splash = Gtk2::Ex::Splash->new;
  $splash->destroy;
  require Scalar::Util;
  Scalar::Util::weaken ($splash);
  is ($splash, undef, 'garbage collect when weakened');
}

exit 0;
