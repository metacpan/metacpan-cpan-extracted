#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;

{
  print ~0,"\n";

  require Math::BigInt;
  my $x = Math::BigInt->new("54043196132425725");
  print "$x\n";
  my $bin = $x->as_bin;
  $bin =~ s/0b//;
  print "$bin\n";
  my $rbin = reverse $bin;
  print "$rbin\n";
  my $r = Math::BigInt->from_bin($rbin);
  print "$r\n";
  my $add = $x + $r;
  print "$add\n";

  print "\n";

  require Math::NumSeq::Emirps;
  $x = 54043196132425725;
  print "$x\n";
  $r = Math::NumSeq::Emirps::_reverse_in_radix($x,2);
  print "$r\n";
  $add = $x + $r;
  print "$add\n";
  exit 0;
}

{
  require Math::BigInt;
  my $two = Math::BigInt->new(2);
  foreach my $k (0 .. 20) {
    my $a = 3*(2**(2*$k + 1) - 2**$k);
    printf "%b\n", $a;
    my $b = 3*(2**(2*$k + 1) + 2**$k - 1);
    printf "%b\n", $b;
    my $c = 3*(2**(2*$k + 2) - 2**$k);
    printf "%b\n", $c;
    my $d = 3*(2**(2*$k + 2) + 3*2**$k - 1);
    printf "%b\n", $d;
  }
  exit 0;
}

{
  require Math::BigInt;
  eval { Math::BigInt->import (try => 'GMP') };

  my $k = Math::BigInt->new(196);
  foreach (1 .. 50) {
    print "$k\n";
    $k += Math::BigInt->new (reverse $k);
  }

  exit 0;
}

