#!/usr/bin/perl -w

# Copyright 2007, 2008, 2009, 2010, 2011 Kevin Ryde

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
use Devel::Mallinfo ':all';
use Test;
BEGIN {
  plan tests => 5;
}

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

ok (defined &mallinfo,
    1,
    'mallinfo() imported');

foreach ('malloc_stats',
         'malloc_info',
         'malloc_info_string',
         'malloc_trim') {
  my $name = $_;
  my $fullname = "Devel::Mallinfo::$name";
  if (defined &$fullname) {
    ok (defined &$name,
        1,
        "$name() imported");
  } else {
    ok (! defined &$name,
        1,
        "$name() not imported as doesn't exist");
  }
}

exit 0;
