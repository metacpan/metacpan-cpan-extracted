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
use Test::More tests => 12;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::Dashes;

{
  my $want_version = 2;
  is ($Gtk2::Ex::Dashes::VERSION, $want_version, 'VERSION variable');
  is (Gtk2::Ex::Dashes->VERSION,  $want_version, 'VERSION class method');

  ok (eval { Gtk2::Ex::Dashes->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::Dashes->VERSION($check_version); 1 },
      "VERSION class check $check_version");

  my $dashes = Gtk2::Ex::Dashes->new;
  is ($dashes->VERSION, $want_version, 'VERSION object method');
  ok (eval { $dashes->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  ok (! eval { $dashes->VERSION($check_version); 1 },
      "VERSION object check $check_version");
}

require Gtk2;
use lib 't';
require MyTestHelpers;
MyTestHelpers::glib_gtk_versions();

#-----------------------------------------------------------------------------
# size_request

{
  my $dashes = Gtk2::Ex::Dashes->new;
  my $req = $dashes->size_request;
  is ($req->width, 0, 'size_request() horizontal width');
  cmp_ok ($req->height, '>=', 1, 'size_request() horizontal height');

  $dashes->set (orientation => 'vertical');
  $req = $dashes->size_request;
  cmp_ok ($req->width, '>=', 1, 'size_request() vertical width');
  is ($req->height, 0, 'size_request() vertical height');
}

#-----------------------------------------------------------------------------
# weaken()

{
  my $dashes = Gtk2::Ex::Dashes->new;
  require Scalar::Util;
  Scalar::Util::weaken ($dashes);
  is ($dashes, undef, 'garbage collect when weakened');
}

exit 0;
