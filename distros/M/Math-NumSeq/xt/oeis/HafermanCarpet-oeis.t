#!/usr/bin/perl -w

# Copyright 2012, 2013, 2019 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
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

use Test;
plan tests => 1;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::HafermanCarpet;


#------------------------------------------------------------------------------
# A118005 num black cells after n iterations
#  = ((-1)^n*5^(n+1) + 9^(n+1)) / 14
#  = (9^(n+1) - (-5)^(n+1)) / 14

# n       0 1  2   3    4     5      6
# A118005 1,4,61,424,4441,36844,347221
# start0  0,4,36,424,3816,36844,331596
# start1  1,9,61,549,4441,39969,347221     start1 = start0 + 5^n
# diff    1 5 25 124  625
#
# if start from single 0 cell then 1s count is
# 0,9,36,549,3816,39969
# ones = A118005(n) - (-1)^n*5^n
#      = ( (-1)^n*5^(n+1) + 9^(n+1) ) / 14 - (-1)^n*5^n
#      = ( 5*(-1)^n*5^n - 14*(-1)^n*5^n + 9^(n+1) ) / 14
#      = ( -9*(-1)^n*5^n + 9^(n+1) ) / 14
#      = (9^n - (-5)^n)*9/14
#      = (9^(n+1) - 9*(-5)^n) / 14


# 0->111,111,111   ones[n+1]  = 9*zeros[n] + 4*ones[n]
# 1->010,101,010   zeros[n+1] = 5*ones[n]
# ones[n+1] = 9*(5*ones[n-1]) + 4*ones[n]
#           = 4*ones[n] + 45*ones[n-1]
# start0 ones[0] = 1
#        ones[1] = 4
#        ones[2] = 4*4 + 45  = 61
#                = 4^2 + 45
#        ones[3] = 4*(4^2 + 45) + 45*4 = 424
#                = 4^3 + 4*45 + 45*4
#                = 4^3 + 2*4*45
#        ones[4] = 4*(4^3 + 2*4*45) + 45*(4^2 + 45)
#                = 4^4 + 2*45*4^2 + 45*4^2 + 45^2
#                = 4^4 + 3*4^2*45 + 45^2
#        ones[5] = 4*(4^4 + 3*45*4^2 + 45^2) + 45*(4^3 + 2*4*45)
#                = 4^5 + 3*45*4^3 + 4*45^2 + 45*4^3 + 2*4*45^2
#                = 4^5 + 4*45*4^3 + 3*4*45^2  = 36844
#        ones[6] = 4*(4^5 + 4*45*4^3 + 3*4*45^2) + 45*(4^4 + 3*45*4^2 + 45^2)
#                = 4^6 + 4*45*4^4 + 3*4^2*45^2 + 45*4^4 + 3*45^2*4^2 + 45^3
#                = 4^6 + 5*4^4*45 + 6*4^2*45^2 + 45^3  = 347221

# cf box density
# all even digits 0,2,4,6,8
# so 1,5,25,... = 5^n

MyOEIS::compare_values
  (anum => 'A118005',
   max_value => 500_000,
   func => sub {
     my ($count) = @_;
     # seq is with a fixed initial 0 or 1
     # A118005 is with middle 1, so alternates initial 0 or 1
     # count both initial 0 or 1 and put the relevant into the return
     my $seq0 = Math::NumSeq::HafermanCarpet->new (initial_value => 0);
     my $seq1 = Math::NumSeq::HafermanCarpet->new (initial_value => 1);
     my @got;
     my $pow = 1;
     my $start0 = 0;
     my $start1 = 0;
     while (@got < $count) {
       {
         my ($i, $value) = $seq0->next;
         if ($i == $pow) {
           push @got, (scalar(@got) & 1 ? $start0 : $start1);
           $pow *= 9;
         }
         $start0 += $value;
       }
       {
         my ($i, $value) = $seq1->next;
         $start1 += $value;
       }
     }
     return \@got;
   });

#------------------------------------------------------------------------------
exit 0;
