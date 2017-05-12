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

use 5.010;
use strict;
use warnings;
use POSIX;

#use Devel::Comments;

{
  require Math::BigFloat;
  Math::BigFloat->import (try => 'GMP');
  Math::BigFloat->round_mode('-inf');
  for (my $digits = 2; $digits < 10000000; $digits *= 2) {
    print "$digits\n";
    # my $f = Math::BigFloat->new(0);
    # $f->precision($digits);
    my $f = Math::BigFloat->bpi($digits);
    # print $f, "\n";
  }
  exit 0;
}

