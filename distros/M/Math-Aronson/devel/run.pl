#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-Aronson.
#
# Math-Aronson is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Aronson is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Aronson.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Math::Aronson;

{
  my $aronson = Math::Aronson->new (lang => 'fr',
                                    # letter => 'F',
                                    # initial_string => "I think T is",
                                    # lying => 1,
                                   );
  ### $aronson
  foreach (1 .. 50) {
    my $n = $aronson->next;
    print "", (defined $n ? $n : 'undef'), "\n";
    if (! defined $n) {
      last;
    }
  }
  exit 0;
}




# http://www.research.att.com/~njas/sequences/A080520
#
# 1, 2, 9, 12, 14, 16, 20, 22, 24, 28, 30, 36, 38, 47, 49, 51, 55, 57, 64,
# 66, 73, 77, 79, 91, 93, 104, 106, 109, 113, 115, 118, 121, 126, 128, 131,
# 134, 140, 142, 150, 152, 156, 158, 166, 168, 172, 174, 183, 184, 189, 191,
# 200, 207, 209, 218, 220, 224, 226, 234, 241
