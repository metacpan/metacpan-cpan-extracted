#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
plan tests => 1426;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::DivisibleColumns;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 127;
  ok ($Math::PlanePath::DivisibleColumns::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::DivisibleColumns->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::DivisibleColumns->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::DivisibleColumns->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::DivisibleColumns->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# n_start(), x_negative(), y_negative()

{
  my $path = Math::PlanePath::DivisibleColumns->new;
  ok ($path->n_start, 0, 'n_start() 0');
  ok ($path->x_negative, 0, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
}
{
  my $path = Math::PlanePath::DivisibleColumns->new (n_start => 123);
  ok ($path->n_start, 123, 'n_start() 123');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::DivisibleColumns->parameter_info_list;
  ok (join(',',@pnames), 'divisor_type,n_start');
}


#------------------------------------------------------------------------------
# _count_divisors()

foreach my $elem (
                  [ 1, 1 ], # 1 itself only
                  [ 2, 2 ], # 1,2 only
                  [ 3, 2 ], # 1,3
                  [ 4, 3 ], # 1,2,4
                  [ 5, 2 ], # 1,5
                  [ 6, 4 ], # 1,2,3,6
                  [ 7, 2 ], # 1,7
                 ) {
  my ($x, $want) = @$elem;
  my $got = Math::PlanePath::DivisibleColumns::_count_divisors($x);
  ok ($got, $want, "_count_divisors($x)");
}

foreach my $x (1 .. 500) {
  my $got = Math::PlanePath::DivisibleColumns::_count_divisors($x);
  my $want = divisors_by_mod($x);
  ok ($got, $want, "_count_divisors($x) vs x%y");
}
sub divisors_by_mod {
  my ($x) = @_;
  my $count = 0;
  foreach my $y (1 .. $x) {
    $count += (($x % $y) == 0);
  }
  return $count;
}


#------------------------------------------------------------------------------
# _count_divisors_cumulative()

foreach my $elem (
                  [ 1, 1 ], # 1 itself only
                  [ 2, 2+1 ], # 1,2 only
                  [ 3, 2+2+1 ], # 1,3
                  [ 4, 3+2+2+1 ], # 1,2,4
                  [ 5, 2+3+2+2+1 ], # 1,5
                  [ 6, 4+2+3+2+2+1 ], # 1,2,3,6
                  [ 7, 2+4+2+3+2+2+1 ], # 1,7
                 ) {
  my ($x, $want) = @$elem;
  my $got = Math::PlanePath::DivisibleColumns::_count_divisors_cumulative($x);
  ok ($got, $want, "_count_divisors_cumulative($x)");
}

{
  my $want = 0;
  foreach my $x (1 .. 500) {
    my $got = Math::PlanePath::DivisibleColumns::_count_divisors_cumulative($x);
    $want += divisors_by_mod($x);
    ok ($got, $want, "_count_divisors($x) vs x%y");
  }
}


#------------------------------------------------------------------------------
# first few points

# {
#   my @data = ([ 0,  1,1 ],
#               [ 1,  2,1 ],
# 
#               [ 2,  3,1 ],
#               [ 3,  3,2 ],
# 
#               [ 4,  4,1 ],
#               [ 5,  4,3 ],
# 
#               [ 6,  5,1 ],
#               [ 7,  5,2 ],
#               [ 8,  5,3 ],
#               [ 9,  5,4 ],
# 
#               [ 10,  6,1 ],
#               [ 11,  6,5 ],
# 
#               [ 12,  7,1 ],
# 
#               [ -0.5,   1,  .5 ],
#               [ -0.25,  1,  .75 ],
#               [ .25,    1, 1.25 ],
#              );
#   my $path = Math::PlanePath::DivisibleColumns->new;
#   foreach my $elem (@data) {
#     my ($n, $want_x, $want_y) = @$elem;
#     my ($got_x, $got_y) = $path->n_to_xy ($n);
#     ok ($got_x, $want_x, "n_to_xy() x at n=$n");
#     ok ($got_y, $want_y, "n_to_xy() y at n=$n");
#   }
# 
#   foreach my $elem (@data) {
#     my ($want_n, $x, $y) = @$elem;
#     next unless $want_n==int($want_n);
#     my $got_n = $path->xy_to_n ($x, $y);
#     ok ($got_n, $want_n, "n at x=$x,y=$y");
#   }
# 
#   foreach my $elem (@data) {
#     my ($n, $x, $y) = @$elem;
#     my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
#     next unless $n==int($n);
#     ok ($got_nlo <= $n, 1, "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
#     ok ($got_nhi >= $n, 1, "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
#   }
# }
# 
# 
# #------------------------------------------------------------------------------
# # xy_to_n() distinct n
# 
# {
#   my $path = Math::PlanePath::DivisibleColumns->new;
#   my $bad = 0;
#   my %seen;
#   my $xlo = -5;
#   my $xhi = 100;
#   my $ylo = -5;
#   my $yhi = 100;
#   my ($nlo, $nhi) = $path->rect_to_n_range($xlo,$ylo, $xhi,$yhi);
#   my $count = 0;
#  OUTER: for (my $x = $xlo; $x <= $xhi; $x++) {
#     for (my $y = $ylo; $y <= $yhi; $y++) {
#       next if ($x ^ $y) & 1;
#       my $n = $path->xy_to_n ($x,$y);
#       next if ! defined $n;  # sparse
# 
#       if ($seen{$n}) {
#         MyTestHelpers::diag ("x=$x,y=$y n=$n seen before at $seen{$n}");
#         last if $bad++ > 10;
#       }
#       if ($n < $nlo) {
#         MyTestHelpers::diag ("x=$x,y=$y n=$n below nlo=$nlo");
#         last OUTER if $bad++ > 10;
#       }
#       if ($n > $nhi) {
#         MyTestHelpers::diag ("x=$x,y=$y n=$n above nhi=$nhi");
#         last OUTER if $bad++ > 10;
#       }
#       $seen{$n} = "$x,$y";
#       $count++;
#     }
#   }
#   ok ($bad, 0, "xy_to_n() coverage and distinct, $count points");
# }

#------------------------------------------------------------------------------
# rect_to_n_range() exact along X=Y diagonal

{
  my $path = Math::PlanePath::DivisibleColumns->new;
  foreach my $i (1 .. 200) {
    my ($nlo, $nhi) = $path->rect_to_n_range($i,0, $i,$i);
    my $want_n_lo = $path->xy_to_n($i,1);
    my $want_n_hi = $path->xy_to_n($i,$i);
    ok ($nlo, $want_n_lo, "nlo exact on X=$i,Y=1");
    ok ($nhi, $want_n_hi, "nhi exact on X=Y=$i line");
  }
}

exit 0;
