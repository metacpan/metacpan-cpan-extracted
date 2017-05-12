#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Gtk2-Ex-QuadButton.
#
# Gtk2-Ex-QuadButton is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-QuadButton is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-QuadButton.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::QuadButton;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
plan tests => 12;

{
  my $want_version = 1;
  is ($Gtk2::Ex::QuadButton::VERSION, $want_version, 'VERSION variable');
  is (Gtk2::Ex::QuadButton->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Gtk2::Ex::QuadButton->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::QuadButton->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $qb = Gtk2::Ex::QuadButton->new;
  is ($qb->VERSION, $want_version, 'VERSION object method');
  ok (eval { $qb->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $qb->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# weaken()

{
  my $qb = Gtk2::Ex::QuadButton->new;
  require Scalar::Util;
  Scalar::Util::weaken ($qb);
  is ($qb, undef,
      'garbage collect when weakened');
}

#------------------------------------------------------------------------------
# size_request()

# vertical
{
  my $qb = Gtk2::Ex::QuadButton->new;
  my $req = $qb->size_request;
  cmp_ok ($req->width, '>', 0);  # always has tick width
  cmp_ok ($req->height, '>', 0);

  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->set_default_size (100, 100);
  $toplevel->add ($qb);
  $toplevel->show_all;
  $qb->size_request;
  $toplevel->destroy;
}

# realized without any Adjustment
{
  my $qb = Gtk2::Ex::QuadButton->new;
  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->add ($qb);
  $toplevel->show_all;
  my $req = $qb->size_request;
  cmp_ok ($req->width, '>=', 0);
  cmp_ok ($req->height, '>=', 0);
}

exit 0;
