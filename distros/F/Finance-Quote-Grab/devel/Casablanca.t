#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2015 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use Test::More tests => 4;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Finance::Quote::Casablanca;

my $want_version = 15;
is ($Finance::Quote::Casablanca::VERSION, $want_version,
    'VERSION variable');
is (Finance::Quote::Casablanca->VERSION,  $want_version,
    'VERSION class method');
{ ok (eval { Finance::Quote::Casablanca->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Finance::Quote::Casablanca->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

exit 0;
