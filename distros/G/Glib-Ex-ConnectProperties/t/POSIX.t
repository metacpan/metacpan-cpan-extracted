#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use POSIX ();
use Test::More;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

if (POSIX::DBL_MANT_DIG() - POSIX::FLT_MANT_DIG() < 10) {
  plan skip_all => 'due to "float" and "double" the same size';
}
plan tests => 4;

require Glib::Ex::ConnectProperties;
require Glib;

## no critic (ProtectPrivateSubs)

my $N = POSIX::FLT_MANT_DIG() + 5;
diag "FLT_MANT_DIG=",POSIX::FLT_MANT_DIG(),
  ", DBL_MANT_DIG=",POSIX::DBL_MANT_DIG(),
  ", test with N=$N";

{
  my $pspec = Glib::ParamSpec->float ('foo','foo','blurb',
                                      0,100,0,['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       2 ** $N,
       2 ** $N),
      "2**N same values equal");
  ok (Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       2 ** $N,
       2 ** $N + 1),
      "2**N + 1 rounds to 2**N in a float");
}

{
  my $pspec = Glib::ParamSpec->double ('foo','foo','blurb',
                                       0,100,0,['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       2 ** $N,
       2 ** $N),
      "2**N same values equal");
  ok (! Glib::Ex::ConnectProperties::_pspec_equal
      ($pspec,
       2 ** $N,
       2 ** $N + 1),
      "2**N + 1 doesn't round to 2**N in a double");
}

exit 0;
