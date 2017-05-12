#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010 Kevin Ryde

# This file is part of Gtk2-Ex-NoShrink.
#
# Gtk2-Ex-NoShrink is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-NoShrink is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-NoShrink.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use lib 't';
use Test::More tests => 10;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Gtk2::Ex::NoShrink;

my $want_version = 4;
is ($Gtk2::Ex::NoShrink::VERSION, $want_version, 'VERSION variable');
is (Gtk2::Ex::NoShrink->VERSION,  $want_version, 'VERSION class method');
{
  ok (eval { Gtk2::Ex::NoShrink->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Gtk2::Ex::NoShrink->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

require Gtk2;
require MyTestHelpers;
MyTestHelpers::glib_gtk_versions();

#-----------------------------------------------------------------------------
# new() and weaken

{
  my $noshrink = Gtk2::Ex::NoShrink->new;

  is ($noshrink->VERSION, $want_version, 'VERSION object method');
  ok (eval { $noshrink->VERSION($want_version); 1 },
      "VERSION object check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { $noshrink->VERSION($check_version); 1 },
      "VERSION object check $check_version");

  require Scalar::Util;
  Scalar::Util::weaken ($noshrink);
  is ($noshrink, undef, 'garbage collected when weakened, when empty');
}

{
  my $noshrink = Gtk2::Ex::NoShrink->new;
  my $label    = Gtk2::Label->new ('hello');
  $noshrink->add ($label);
  Scalar::Util::weaken ($label);
  Scalar::Util::weaken ($noshrink);

  is ($noshrink, undef, 'garbage collected when weakened, when not empty');
  is ($label, undef, 'child label garbage collected when weakened');
}

exit 0;
