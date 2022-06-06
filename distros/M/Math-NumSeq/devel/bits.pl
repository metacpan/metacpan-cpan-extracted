#!/usr/bin/perl -w

# Copyright 2010, 2011, 2022 Kevin Ryde

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
# use Math::BigInt try => 'GMP';
$|=1;

# use Math::BigInt try => 'Calc';

{
  require Math::BigInt;
  require Math::BigFloat;
  print "Math::BigFloat version ",Math::BigFloat->VERSION,"\n";
  my $nan = Math::BigFloat->bnan('-');
  print $nan,"\n";
  exit 0;
}

{
  require Math::NumSeq;
  require Math::BigFloat;
  Math::BigFloat->import;
  my $x = Math::BigFloat->binf();
  my $ret = ($x != $x);
  print "$ret\n";

  # # my $ret = Math::NumSeq::_is_infinite($biginf);
  # print "$ret\n";
  #
  # # return (
  # #         || ($x != 0 && $x == 2*$x));  # inf

  exit 0;
}


#my $bits = 100;

# my $factor = Math::BigInt->new(1);
# $factor <<= $bits;
# print $factor->as_hex,"\n";


my $str = ln3_binary(200);
$,="\n";
print binary_positions(ln3_binary(200));




