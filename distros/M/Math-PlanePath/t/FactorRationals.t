#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016 Kevin Ryde

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
plan tests => 291;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::FactorRationals;

my $path = Math::PlanePath::FactorRationals->new;
my $n_start = $path->n_start;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 124;
  ok ($Math::PlanePath::FactorRationals::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::FactorRationals->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::FactorRationals->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::FactorRationals->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

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
  ok ($n_start, 1, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::FactorRationals->parameter_info_list;
  ok (join(',',@pnames), 'factor_coding');
}


#------------------------------------------------------------------------------
# first few points

{
  my @data = (
              [ 2**31, 1, 2**16 ],
              [ 2**200, 2**100, 1 ],

              [ undef,  0,0 ],
              [ undef,  1,0 ],
              [ undef,  2,0 ],
              [ undef,  3,0 ],

              [ undef,  0,1 ],
              [ undef,  0,2 ],
              [ undef,  0,3 ],

              [ 1,  1,1 ],

              [ 2,  1,2 ],
              [ 4,  2,1 ],
              [ 8,  1,4 ],
              [ 16,  4,1 ],
              [ 32,  1,8 ],
              [ 64,  8,1 ],

              [ 3,  1,3 ],
              [ 9,  3,1 ],
              [ 27,  1,9 ],
              [ 81,  9,1 ],

              [ 45,  3,5 ], # 3^2*5

              # Listing in Umberto Cerruti "Ordinare i Razionali: Gli Alberi
              # di Keplero e di Calkin-Wilf"
              # http://www.dm.unito.it/~cerruti/pdfblog/ordinamenti.pdf
              # http://www.dm.unito.it/~cerruti/mathblog.html
              # But inverted since mapping even B(2k)=-k odd B(2k-1)=k.
              [ 1,  1,1 ],
              [ 2,  1,2 ],
              [ 3,  1,3 ],
              [ 4,  2,1 ],
              [ 5,  1,5 ],
              [ 6,  1,6 ],
              [ 7,  1,7 ],
              [ 8,  1,4 ],
              [ 9,  3,1 ],
              [ 10,  1,10 ],
              [ 11,  1,11 ],
              [ 12,  2,3 ],
              [ 13,  1,13 ],
              [ 14,  1,14 ],
              [ 15,  1,15 ],
              [ 16,  4,1 ],
              [ 17,  1,17 ],
              [ 18,  3,2 ],
              [ 19,  1,19 ],
              [ 20,  2,5 ],
              [ 21,  1,21 ],
              [ 22,  1,22 ],
              [ 23,  1,23 ],
              [ 24,  1,12 ],
              [ 25,  5,1 ],
              [ 26,  1,26 ],
              [ 27,  1,9 ],
              [ 28,  2,7 ],
              [ 29,  1,29 ],
              [ 30,  1,30 ],

              [ 66395120,  44,1805 ],

             );
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    next if ! defined $n;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    ok ($got_x, $want_x, "n_to_xy() x at n=$n");
    ok ($got_y, $want_y, "n_to_xy() y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    next if defined $want_n && $want_n!=int($want_n);
    my $got_n = $path->xy_to_n ($x, $y);
    ok ($got_n, $want_n, "xy_to_n() at x=$x,y=$y");
  }

  foreach my $elem (@data) {
    my ($n, $x, $y) = @$elem;
    next unless defined $n && $n==int($n);
    my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
    ok ($got_nlo >= $n_start, 1, "rect_to_n_range() nlo=$got_nlo < n_start at n=$n,x=$x,y=$y");
    ok ($got_nlo <= $n, 1, "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
    ok ($got_nhi >= $n, 1, "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
  }
}


#------------------------------------------------------------------------------
# xy_to_n() distinct n

{
  my $bad = 0;
  my %seen;
  my $xlo = -5;
  my $xhi = 100;
  my $ylo = -5;
  my $yhi = 100;
  my ($nlo, $nhi) = $path->rect_to_n_range($xlo,$ylo, $xhi,$yhi);
  my $count = 0;
 OUTER: for (my $x = $xlo; $x <= $xhi; $x++) {
    for (my $y = $ylo; $y <= $yhi; $y++) {
      next if ($x ^ $y) & 1;
      my $n = $path->xy_to_n ($x,$y);
      next if ! defined $n;  # sparse

      if ($seen{$n}) {
        MyTestHelpers::diag ("x=$x,y=$y n=$n seen before at $seen{$n}");
        last if $bad++ > 10;
      }
      if ($n < $nlo) {
        MyTestHelpers::diag ("x=$x,y=$y n=$n below nlo=$nlo");
        last OUTER if $bad++ > 10;
      }
      if ($n > $nhi) {
        MyTestHelpers::diag ("x=$x,y=$y n=$n above nhi=$nhi");
        last OUTER if $bad++ > 10;
      }
      $seen{$n} = "$x,$y";
      $count++;
    }
  }
  ok ($bad, 0, "xy_to_n() coverage and distinct, $count points");
}

#------------------------------------------------------------------------------
# rect_to_n_range()

{
  my ($nlo, $nhi) = $path->rect_to_n_range(1,1, -2,1);
  ### $nlo
  ### $nhi
  ok ($nlo <= 1, 1, "nlo $nlo");
  ok ($nhi >= 1, 1, "nhi $nhi");
}

exit 0;
