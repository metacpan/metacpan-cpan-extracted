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


# This is a few lines of nonsense showing which letters make finite or
# infinite sequences, or apparently infinite.
#
# The letters like "Z" which end at 1 are because in "Z is the first"
# there's that first Z but no more.  Only the letters in "is the first" can
# continue past the first (or corresponding "est la premiere" for French).
#

use 5.004;
use strict;
use Math::Aronson;

foreach my $lang ('en', 'fr') {
  print "lang $lang\n";

  foreach my $letter ('A' .. 'Z') {
    my @show;
    foreach my $without_conjunctions (0, 1) {
      my $aronson = Math::Aronson->new
        (lang => $lang,
         letter => $letter,
         without_conjunctions => $without_conjunctions);
      my $value;
      my $i = 0;
      for (;;) {
        if ($i++ > 5000) {
          push @show, "infinite";
          last;
        }
        my $next = $aronson->next;
        if (! defined $next) {
          push @show, "ends at $value";
          last;
        }
        $value = $next;
      }
    }
    if ($show[0] ne $show[1]) {
      $show[0] .= ", or without conjunctions $show[1]";
    }
    print "$letter $show[0]\n";
  }
  print "\n";
}
exit 0;
