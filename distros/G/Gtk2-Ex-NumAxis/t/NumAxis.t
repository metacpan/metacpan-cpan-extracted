#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-NumAxis.
#
# Gtk2-Ex-NumAxis is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-NumAxis is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NumAxis.  If not, see <http://www.gnu.org/licenses/>.


use 5.008;
use strict;
use warnings;
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::NumAxis;

require Gtk2;
Gtk2->disable_setlocale;  # leave LC_NUMERIC alone for version nums
Gtk2->init_check
  or plan skip_all => 'due to no DISPLAY available';
plan tests => 31;

{
  my $want_version = 5;
  is ($Gtk2::Ex::NumAxis::VERSION, $want_version, 'VERSION variable');
  is (Gtk2::Ex::NumAxis->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Gtk2::Ex::NumAxis->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::NumAxis->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $axis = Gtk2::Ex::NumAxis->new;
  is ($axis->VERSION, $want_version, 'VERSION object method');
  ok (eval { $axis->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $axis->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
{
  ## no critic (ProtectPrivateSubs)
  is (Gtk2::Ex::NumAxis::_num_integer_digits(0),       1);
  is (Gtk2::Ex::NumAxis::_num_integer_digits(99),      2);
  is (Gtk2::Ex::NumAxis::_num_integer_digits(100.25),  3);
  is (Gtk2::Ex::NumAxis::_num_integer_digits(-100.25), 3);
}

#------------------------------------------------------------------------------
{
  my @values;
  @values = Gtk2::Ex::NumAxis::round_up_2_5_pow_10(0.0099);
  is_deeply (\@values, [0.01, 2]);
  @values = Gtk2::Ex::NumAxis::round_up_2_5_pow_10(0.15);
  is_deeply (\@values, [0.2, 1]);
  @values = Gtk2::Ex::NumAxis::round_up_2_5_pow_10(3.5);
  is_deeply (\@values, [5, 0]);
  @values = Gtk2::Ex::NumAxis::round_up_2_5_pow_10(60);
  is_deeply (\@values, [100, 0]);
}

#------------------------------------------------------------------------------
{
  # this checks the sense of nhimult is what's desired by NumAxis
  require Math::Round;
  is (Math::Round::nhimult(10,  95),    100, 'nhimult 10,95');
  is (Math::Round::nhimult(0.5, 1.333), 1.5, 'nhimult 0.5,1.333');
  is (Math::Round::nhimult(5,   -10),   -10, 'nhimult 5,-10');
}

#------------------------------------------------------------------------------
# weaken()

{
  my $axis = Gtk2::Ex::NumAxis->new;
  require Scalar::Util;
  Scalar::Util::weaken ($axis);
  is ($axis, undef,
      'garbage collect when weakened');
}

{
  my $adj = Gtk2::Adjustment->new (2100, 0, 4500, 1, 10, 300);
  my $axis = Gtk2::Ex::NumAxis->new (adjustment => $adj);
  require Scalar::Util;
  Scalar::Util::weaken ($axis);
  is ($axis, undef,
      'garbage collect when weakened -- with adj');
}

#------------------------------------------------------------------------------
# set_scroll_adjustments()

{
  my $axis = Gtk2::Ex::NumAxis->new;
  my $a1 = Gtk2::Adjustment->new (2100, 0, 4500, 1, 10, 300);
  my $a2 = Gtk2::Adjustment->new (2100, 0, 4500, 1, 10, 300);
  $axis->set_scroll_adjustments ($a1, $a2);
  is ($axis->get('adjustment'), $a2);
}

#------------------------------------------------------------------------------
# size_request()

# vertical
{
  my $axis = Gtk2::Ex::NumAxis->new;
  my $req = $axis->size_request;
  cmp_ok ($req->width, '>', 0);  # always has tick width
  cmp_ok ($req->height, '==', 0);

  my $empty_width = $req->width;

  $axis->set (adjustment => Gtk2::Adjustment->new (2100,0,4500,1,10,300));
  $req = $axis->size_request;
  cmp_ok ($req->width, '>', $empty_width);
  cmp_ok ($req->height, '==', 0);

  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->set_default_size (100, 100);
  $toplevel->add ($axis);
  $toplevel->show_all;
  $axis->size_request;
  $toplevel->destroy;
}

# horizontal
{
  my $axis = Gtk2::Ex::NumAxis->new (orientation => 'horizontal');
  my $req = $axis->size_request;
  cmp_ok ($req->width, '==', 0);
  cmp_ok ($req->height, '>', 0);  # always has tick width

  my $empty_height = $req->height;

  $axis->set (adjustment => Gtk2::Adjustment->new (2100,0,4500,1,10,300));
  $req = $axis->size_request;
  cmp_ok ($req->width, '==', 0);
  cmp_ok ($req->height, '>=', $empty_height);

  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->set_default_size (100, 100);
  $toplevel->add ($axis);
  $toplevel->show_all;
  $axis->size_request;
  $toplevel->destroy;
}

# realized without any Adjustment
{
  my $axis = Gtk2::Ex::NumAxis->new;
  my $toplevel = Gtk2::Window->new ('toplevel');
  $toplevel->add ($axis);
  $toplevel->show_all;
  my $req = $axis->size_request;
  cmp_ok ($req->width, '>=', 0);
  cmp_ok ($req->height, '==', 0);
}

exit 0;

