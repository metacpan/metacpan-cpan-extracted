#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011, 2014 Kevin Ryde

# This file is part of Devel-Mallinfo.

# Devel-Mallinfo is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Devel-Mallinfo is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Devel-Mallinfo.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Devel::Mallinfo ('mallinfo');
use Test;
BEGIN {
  plan tests => 6;
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

my $want_version = 14;
ok ($Devel::Mallinfo::VERSION,
    $want_version,
    'VERSION variable');
ok (Devel::Mallinfo->VERSION,
    $want_version,
    'VERSION class method');
{
  ok (eval { Devel::Mallinfo->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Devel::Mallinfo->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");
}

ok (defined &mallinfo,
    1,
    'mallinfo() defined in local module');

# get back a hash, though what it contains is system-dependent
my $h = mallinfo();
ok (ref($h),
    'HASH',
    'mallinfo() returns hash');

exit 0;
