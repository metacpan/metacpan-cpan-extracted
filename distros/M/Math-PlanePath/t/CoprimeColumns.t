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
plan tests => 236;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

use Math::PlanePath::CoprimeColumns;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 127;
  ok ($Math::PlanePath::CoprimeColumns::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::CoprimeColumns->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::CoprimeColumns->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::CoprimeColumns->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::CoprimeColumns->new;
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
  my $path = Math::PlanePath::CoprimeColumns->new;
  ok ($path->n_start, 0, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative()');
  ok ($path->y_negative, 0, 'y_negative()');
  ok ($path->class_x_negative, 0, 'class_x_negative() instance method');
  ok ($path->class_y_negative, 0, 'class_y_negative() instance method');
}
{
  my $path = Math::PlanePath::CoprimeColumns->new (n_start => 37);
  ok ($path->n_start, 37, 'n_start() 37');
}
{
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::CoprimeColumns->parameter_info_list;
  ok (join(',',@pnames), 'direction,n_start');
}


#------------------------------------------------------------------------------
# _coprime()

foreach my $elem ([ 1,1,  1 ],
                  [ 6,1,  1 ],
                  [ 6,2,  0 ],
                  [ 6,3,  0 ],
                  [ 6,4,  0 ],
                  [ 6,5,  1 ],
                 ) {
  my ($x,$y, $want) = @$elem;
  {
    my $got = Math::PlanePath::CoprimeColumns::_coprime($x,$y);
    $got = $got-0;
    ok ($got, $want, "_coprime($x,$y)");
  }
  {
    my $got = Math::PlanePath::CoprimeColumns::_coprime($y,$x);
    $got = $got-0;
    ok ($got, $want, "_coprime($x,$y)");
  }
}

#------------------------------------------------------------------------------
# _totient()

foreach my $elem (
                  [ 1, 1 ], # 1 itself only
                  [ 2, 1 ], # 1 only
                  [ 3, 2 ], # 1,2
                  [ 4, 2 ], # 1,3
                  [ 5, 4 ], # 1,2,3,4
                  [ 6, 2 ], # 1,5
                 ) {
  my ($x, $want) = @$elem;
  my $got = Math::PlanePath::CoprimeColumns::_totient($x);
  ok ($got, $want, "_totient($x)");
}

foreach my $x (1 .. 100) {
  my $want = 0;
  foreach my $y (1 .. $x) {
    $want += Math::PlanePath::CoprimeColumns::_coprime($x,$y);
  }
  my $got = Math::PlanePath::CoprimeColumns::_totient($x);
  ok ($got, $want, "_totient($x) vs _coprime()");
}


#------------------------------------------------------------------------------
# first few points

{
  my @elems = ([ [],
                 [ 0,  1,1 ],
                 [ 1,  2,1 ],

                 [ 2,  3,1 ],
                 [ 3,  3,2 ],

                 [ 4,  4,1 ],
                 [ 5,  4,3 ],

                 [ 6,  5,1 ],
                 [ 7,  5,2 ],
                 [ 8,  5,3 ],
                 [ 9,  5,4 ],

                 [ 10,  6,1 ],
                 [ 11,  6,5 ],

                 [ 12,  7,1 ],

                 [ -0.5,   1,  .5 ],
                 [ -0.25,  1,  .75 ],
                 [ .25,    1, 1.25 ],
               ],

               [ [ direction => 'down' ],

                 [ 2,  3,2 ],
                 [ 3,  3,1 ],

                 [ 6,  5,4 ],
                 [ 7,  5,3 ],
                 [ 8,  5,2 ],
                 [ 9,  5,1 ],
               ],
              );
  foreach my $elem (@elems) {
    my ($options_aref, @data) = @$elem;
    my $path = Math::PlanePath::CoprimeColumns->new (@$options_aref);
    foreach my $elem (@data) {
      my ($n, $want_x, $want_y) = @$elem;
      my ($got_x, $got_y) = $path->n_to_xy ($n);
      ok ($got_x, $want_x, "n_to_xy() x at n=$n");
      ok ($got_y, $want_y, "n_to_xy() y at n=$n");
    }

    foreach my $elem (@data) {
      my ($want_n, $x, $y) = @$elem;
      next unless $want_n==int($want_n);
      my $got_n = $path->xy_to_n ($x, $y);
      ok ($got_n, $want_n, "n at x=$x,y=$y");
    }

    foreach my $elem (@data) {
      my ($n, $x, $y) = @$elem;
      my ($got_nlo, $got_nhi) = $path->rect_to_n_range (0,0, $x,$y);
      next unless $n==int($n);
      ok ($got_nlo <= $n, 1, "rect_to_n_range() nlo=$got_nlo at n=$n,x=$x,y=$y");
      ok ($got_nhi >= $n, 1, "rect_to_n_range() nhi=$got_nhi at n=$n,x=$x,y=$y");
    }
  }
}


#------------------------------------------------------------------------------
# xy_to_n() distinct n

{
  my $path = Math::PlanePath::CoprimeColumns->new;
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
  my $path = Math::PlanePath::CoprimeColumns->new;
  my ($nlo, $nhi) = $path->rect_to_n_range(1,1, -2,1);
  ok ($nlo <= 0, 1, "nlo $nlo");
  ok ($nhi >= 0, 1, "nhi $nhi");
}

exit 0;
