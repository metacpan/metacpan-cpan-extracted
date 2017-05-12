#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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

use 5.010;
use strict;
use List::Util 'min','max';

# uncomment this to run the ### lines
use Smart::Comments;


# a(k)=1 iff k/3 is fibbinary = binary no consecutive 1s
{
  require Math::BaseCnv;
  require Math::NumSeq::Fibbinary;
  my @want = (1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
              1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
              1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
              0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);
  foreach my $i (0 .. $#want) {
    my $ternary = Math::BaseCnv::cnv($i,10,3);

    # my $got = ($ternary =~ /0(00)*$/ ? 1 : 0);
    my $got = (($i % 3) != 0 ? 0
               : Math::NumSeq::Fibbinary->pred($i/3) ? 1 : 0);

    my $want = $want[$i];
    my $diff = ($got  == $want ? '' : '   ***');
    print "$i $ternary  $want   $got $diff\n";
  }
  exit 0;
}

# plain:     1, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1
#       100 100 100 000 100 100 000 000 100 100 100 000 000 000 000 000

# 1,
# 0,    1      1     1
# 0,    2     10     2
# 1,    3     11    10
# 0,    4    100    11
# 0,    5    101    12
# 1,    6    110    20
# 0,    7    111    21
# 0,    8   1000    22
# 0,    9   1001   100
# 0,   10   1010   101
# 0,   11   1011   102
# 1,   12   1100   110
# 0,   13   1101   111
# 0,   14   1110   112
# 1,   15   1111   120
# 0,   16          121
# 0,   17          122
# 0,   18          200
# 0,   19          201   
# 0,   20          202
# 0,   21          210
# 0,   22          211
# 0,   23          212
# 1,   24          220
# 0,   25          221
# 0,   26          222
# 1,   27         1000
# 0,   28         1001
# 0,   29         1002
# 1,   30         1010
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   40  
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 1,   48         1210
# 0,   
# 0,   
# 1,   51         1220
# 0,   
# 0,   
# 1,   54         2000
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 1,   60         2020
# 0,   
# 0,   
# 1,   63         2100
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0,   
# 0

