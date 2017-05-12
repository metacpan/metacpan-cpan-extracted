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
plan tests => 39;;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::CfracDigits;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 124;
  ok ($Math::PlanePath::CfracDigits::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::CfracDigits->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::CfracDigits->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::CfracDigits->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::CfracDigits->new;
  ok ($path->VERSION,  $want_version, 'VERSION object method');

  ok (eval { $path->VERSION($want_version); 1 },
      1,
      "VERSION object check $want_version");
  ok (! eval { $path->VERSION($check_version); 1 },
      1,
      "VERSION object check $check_version");
}


#------------------------------------------------------------------------------
# n_start, x_negative, y_negative

{
  my $path = Math::PlanePath::CfracDigits->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
  ok ($path->class_x_negative, 0, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 0, 'class_y_negative() instance method');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::CfracDigits->parameter_info_list;
  ok (join(',',@pnames), 'radix');
}



#------------------------------------------------------------------------------
# first few points

{
  my @data = ([ 12590,  26,269 ],
             );
  my $path = Math::PlanePath::CfracDigits->new;
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    ok ($got_x, $want_x, "x at n=$n");
    ok ($got_y, $want_y, "y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    next unless $want_n==int($want_n);
    my $got_n = $path->xy_to_n ($x, $y);
    ok ($got_n, $want_n, "n at x=$x,y=$y");
  }
  
  foreach my $elem (@data) {
    my ($n, $x, $y) = @$elem;
    if ($n == int($n)) {
      my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
      ok ($got_nlo == 0, 1, "rect_to_n_range() got_nlo=$got_nlo at n=$n,x=$x,y=$y");
      ok ($got_nhi >= $n, 1, "rect_to_n_range(0,0,$x,$y) got_nhi=$got_nhi at n=$n,x=$x,y=$y");
  
      ($got_nlo, $got_nhi) = $path->rect_to_n_range ($x,$y, $x,$y);
      ok ($got_nlo <= $n, 1, "rect_to_n_range() got_nlo=$got_nlo at n=$n,x=$x,y=$y");
      ok ($got_nhi >= $n, 1, "rect_to_n_range() got_nhi=$got_nhi at n=$n,x=$x,y=$y");
    }
  }
}

#------------------------------------------------------------------------------
# _digit_split_1toR_lowtohigh()

{
  foreach my $elem ([ 3, 12590,  2,2,3,3,1,3,1,2,1 ],  # low to high
                    [ 3, 0,      ], # empty
                    [ 3, 1,      1 ], # empty
                    [ 3, 1,      1 ],
                    [ 3, 2,      2 ],
                    [ 3, 3,      3 ],
                    [ 3, 4,      1,1 ],
                    [ 3, 5,      2,1 ],
                    [ 3, 6,      3,1 ],
                    [ 3, 7,      1,2 ],
                   ) {
    my ($radix, $n, @want_digits) = @$elem;
    my @got_digits = Math::PlanePath::CfracDigits::_digit_split_1toR_lowtohigh($n,$radix);
    my $want_digits = join(',',@want_digits);
    my $got_digits = join(',',@got_digits);
    ok ($want_digits, $got_digits, "_digit_split_1toR() at n=$n radix=$radix");
  }
}

#------------------------------------------------------------------------------
# _n_to_quotients_bottomtotop()

{
  foreach my $elem ([ 2, 12590,  8,1,2,10 ],  # bottom to top
                    [ 2, 0,      2 ],   # N=0 one empty
                    [ 2, 1,      3 ],   # N=1
                    [ 2, 2,      4 ],   # N=2
                    [ 2, 3,      2,1 ], # N=3 two empties
                   ) {
    my ($radix, $n, @want_quotients) = @$elem;
    {
      my @got_quotients = Math::PlanePath::CfracDigits::_n_to_quotients_bottomtotop($n,$radix);
      my $want_quotients = join(',',@want_quotients);
      my $got_quotients = join(',',@got_quotients);
      ok ($got_quotients, $want_quotients,
          "_n_to_quotients() at n=$n radix=$radix");
    }
  }
}

#------------------------------------------------------------------------------
# _cfrac_join_toptobottom()

{
  foreach my $elem ([ 2, 12590,  10,2,1,7 ],  # top to bottom
                    [ 2, 0,      1 ],
                    [ 2, 1,      2 ],
                    [ 2, 3,      1,1 ],
                   ) {
    my ($radix, $n, @quotients) = @$elem;
    {
      my $got_n = Math::PlanePath::CfracDigits::_cfrac_join_toptobottom(\@quotients,$radix);
      ok ($got_n == $n, 1,
          "_quotients_join() at n=$n radix=$radix got_n=$got_n");
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
