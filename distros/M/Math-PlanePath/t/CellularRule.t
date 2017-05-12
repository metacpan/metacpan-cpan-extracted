#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
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
plan tests => 1216;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::CellularRule;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 124;
  ok ($Math::PlanePath::CellularRule::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::CellularRule->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::CellularRule->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::CellularRule->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::CellularRule->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}

#------------------------------------------------------------------------------
# parameter_info_list()

{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::CellularRule->parameter_info_list;
  ok (join(',',@pnames),
      'rule,n_start');
}

#------------------------------------------------------------------------------
# first few points

foreach my $relem ([ 50, # solid odd
                     [ 1, 0,0 ],
                     [ 2, -1,1 ],
                     [ 3, 1,1 ],
                     [ 4, -2,2 ],
                     [ 5, 0,2 ],
                     [ 6, 2,2 ],

                     [ .75,  -0.25, 0 ],
                     [ 1.25,   0.25, 0 ],

                     [ 1.75,  -1-.25, 1 ],
                     [ 2.25,  -1+.25, 1 ],

                     [ 2.75,  1-.25, 1 ],
                     [ 3.25,  1+.25, 1 ],

                     [ 3.75,  -2-.25, 2 ],
                     [ 4.25,  -2+.25, 2 ],

                     [ 4.75,  0-.25, 2 ],
                     [ 5.25,  0+.25, 2 ],

                     [ 5.75,  2-.25, 2 ],
                     [ 6.25,  2+.25, 2 ],
                   ],

                   [ 6, # one,two left
                     [ 1, 0,0 ],
                     [ 2, -1,1 ],
                     [ 3,  0,1 ],
                     [ 4, -2,2 ],
                     [ 5, -3,3 ],
                     [ 6, -2,3 ],
                   ],
                   [ 20, # one,two right
                     [ 1, 0,0 ],
                     [ 2, 0,1 ],
                     [ 3, 1,1 ],
                     [ 4, 2,2 ],
                     [ 5, 2,3 ],
                     [ 6, 3,3 ],
                   ],

                   [ 14, # two left
                     [ 1,  0,0 ],
                     [ 2, -1,1 ],
                     [ 3,  0,1 ],
                     [ 4, -2,2 ],
                     [ 5, -1,2 ],
                     [ 6, -3,3 ],
                     [ 7, -2,3 ],
                   ],

                   [ 84, # two right
                     [ 1, 0,0 ],
                     [ 2, 0,1 ],
                     [ 3, 1,1 ],
                     [ 4, 1,2 ],
                     [ 5, 2,2 ],
                     [ 6, 2,3 ],
                     [ 7, 3,3 ],
                   ],
                  ) {
  my ($rule, @elements) = @$relem;
  my $path = Math::PlanePath::CellularRule->new (rule => $rule);
  foreach my $elem (@elements) {
    my ($n, $x,$y) = @$elem;
    {
      # n_to_xy()
      my ($got_x, $got_y) = $path->n_to_xy ($n);
      if ($got_x == 0) { $got_x = 0 }  # avoid "-0"
      if ($got_y == 0) { $got_y = 0 }
      ok ($got_x, $x, "rule=$rule n_to_xy() x at n=$n");
      ok ($got_y, $y, "rule=$rule n_to_xy() y at n=$n");
    }
    if ($n==int($n)) {
      # xy_to_n()
      my $got_n = $path->xy_to_n ($x, $y);
      ok ($got_n, $n, "rule=$rule xy_to_n() n at x=$x,y=$y");
    }
    if ($n==int($n)) {
      my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
      ok ($got_nlo <= $n, 1, "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
      ok ($got_nhi >= $n, 1, "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y ".(ref $path));
    }
  }
}


#------------------------------------------------------------------------------
# compare CellularRule bit-wise calculation with the specific sub-classes
#

my $bitwise_count = 0;

foreach my $rule (0 .. 255) {
  my $bad_count = 0;

  my $path = Math::PlanePath::CellularRule->new (rule => $rule);
  ok ($path->y_negative, 0, 'y_negative()');
  ok ($path->class_x_negative, 1, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 0, 'class_y_negative() instance method');
  my $got_x_negative = $path->x_negative ? 1 : 0;

  {
    my $saw_x_negative = 0;
    for (my $n = $path->n_start; $n < 50; $n++) {
      my ($x,$y) = $path->n_to_xy($n)
        or last;
      if ($x < 0) {
        $saw_x_negative = 1;
        last;
      }
    }
    if ($got_x_negative != $saw_x_negative) {
      MyTestHelpers::diag ("rule=$rule saw x negative $saw_x_negative vs x_negative() $got_x_negative");
      $bad_count++;
    }
  }

  if (ref $path ne 'Math::PlanePath::CellularRule') {
    MyTestHelpers::diag ("bitwise check rule=$rule");
    $bitwise_count++;
    # copy of CellularRule guts
    my $bitwise = Math::PlanePath::CellularRule->new (rule => $rule,
                                                      use_bitwise => 1);
    foreach my $x (-15 .. 15) {
      foreach my $y (0 .. 15) {
        my $path_n = $path->xy_to_n($x,$y);
        my $bit_n = $bitwise->xy_to_n($x,$y);
        unless ((! defined $path_n && ! defined $bit_n)
                || (defined $path_n && defined $bit_n && $path_n == $bit_n)) {
          MyTestHelpers::diag ("rule=$rule wrong xy_to_n() bitwise at x=$x,y=$y, got bitwise n=",$bit_n," path n=",$path_n);
          if (++$bad_count > 100) { die "Too much badness" };
          ### $bad_count
        }
      }
    }

    foreach my $n (-2 .. 20) {
      my @path_xy = $path->n_to_xy($n);
      my @bit_xy = $bitwise->n_to_xy($n);
      my $path_xy = join(',',@path_xy);
      my $bit_xy = join(',',@bit_xy);
      unless ($path_xy eq $bit_xy) {
        MyTestHelpers::diag ("rule=$rule wrong n_to_xy() bitwise at n=$n");
        if (++$bad_count > 100) { die "Too much badness" };
      }
    }
  }
  ok ($bad_count, 0, "no badness in rule=$rule");
}
MyTestHelpers::diag ("bitwise checks $bitwise_count");


exit 0;
