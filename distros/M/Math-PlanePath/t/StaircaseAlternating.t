#!/usr/bin/perl -w

# Copyright 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

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
plan tests => 37;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

require Math::PlanePath::StaircaseAlternating;


#------------------------------------------------------------------------------
# VERSION

{
  my $want_version = 125;
  ok ($Math::PlanePath::StaircaseAlternating::VERSION, $want_version,
      'VERSION variable');
  ok (Math::PlanePath::StaircaseAlternating->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Math::PlanePath::StaircaseAlternating->VERSION($want_version); 1 },
      1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Math::PlanePath::StaircaseAlternating->VERSION($check_version); 1 },
      1,
      "VERSION class check $check_version");

  my $path = Math::PlanePath::StaircaseAlternating->new;
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
  my $path = Math::PlanePath::StaircaseAlternating->new;
  ok ($path->n_start, 1, 'n_start()');
  ok ($path->x_negative, 0, 'x_negative() instance method');
  ok ($path->y_negative, 0, 'y_negative() instance method');
}
{
  # width not a parameter as such ...
  my @pnames = map {$_->{'name'}}
    Math::PlanePath::StaircaseAlternating->parameter_info_list;
  ok (join(',',@pnames), 'end_type,n_start');
}


#------------------------------------------------------------------------------
# rect_to_n_range() 2x2 blocks

foreach my $end_type ('jump', 'square') {
  my $path = Math::PlanePath::StaircaseAlternating->new(end_type=>$end_type);
  my $bad = 0;
  foreach my $x1 (0 .. 24) {
    foreach my $xblock (0, 1, 2, 10) {
      my $x2 = $x1 + $xblock;

      foreach my $y1 (0 .. 24) {
        foreach my $yblock (0, 1, 2, 10) {
          my $y2 = $y1 + $yblock;

          my @n_list = grep {defined} ($path->xy_to_n($x1,$y1),
                                       $path->xy_to_n($x2,$y2),

                                       ($xblock >= 1
                                        ? ($path->xy_to_n($x1+1,$y1),
                                           $path->xy_to_n($x2-1,$y2))
                                        : ()),
                                       ($xblock >= 2
                                        ? ($path->xy_to_n($x1+2,$y1),
                                           $path->xy_to_n($x2-2,$y2))
                                        : ()),

                                       ($yblock >= 1
                                        ? ($path->xy_to_n($x1,$y1+1),
                                           $path->xy_to_n($x2,$y2-1))
                                        : ()),
                                       ($yblock >= 2
                                        ? ($path->xy_to_n($x1,$y1+2),
                                           $path->xy_to_n($x2,$y2-2))
                                        : ()));

          my $want_nlo = Math::PlanePath::_min (@n_list);
          my $want_nhi = Math::PlanePath::_max (@n_list);
          if (! @n_list) {
            $want_nlo = 1; # crossed
            $want_nhi = 0;
          }

          my ($got_nlo, $got_nhi) = $path->rect_to_n_range ($x1,$y1, $x2,$y2);

          unless ((defined $got_nlo == defined $want_nlo)
                  && ($got_nlo||0) == ($want_nlo||0)) {
            if (! defined $got_nlo) { $got_nlo = 'undef'; }
            if (! defined $want_nlo) { $want_nlo = 'undef'; }
            MyTestHelpers::diag ("$end_type $x1,$y1 to $x2,$y2  want_nlo=$want_nlo got_nlo=$got_nlo");
            $bad++;
          }
          unless ((defined $got_nhi == defined $want_nhi)
                  && ($got_nhi||0) == ($want_nhi||0)) {
            if (! defined $got_nhi) { $got_nhi = 'undef'; }
            if (! defined $want_nhi) { $want_nhi = 'undef'; }
            MyTestHelpers::diag ("$end_type $x1,$y1 to $x2,$y2  want_nhi=$want_nhi got_nhi=$got_nhi");
            $bad++;
          }
        }
      }

    }
  }
  ok ($bad, 0);
}

#------------------------------------------------------------------------------
# first few values, square

{
  my @data = ([ 1, 0,0 ],
              [ 2, 0,1 ],
              [ 3, 1,1 ],
              [ 4, 1,0 ],
              [ 5, 2,0 ],
              [ 6, 3,0 ],
             );
  my $path = Math::PlanePath::StaircaseAlternating->new (end_type=>'square');
  foreach my $elem (@data) {
    my ($n, $want_x, $want_y) = @$elem;
    my ($got_x, $got_y) = $path->n_to_xy ($n);
    ok ($got_x, $want_x, "x at n=$n");
    ok ($got_y, $want_y, "y at n=$n");
  }

  foreach my $elem (@data) {
    my ($want_n, $x, $y) = @$elem;
    next unless $want_n == int($want_n);
    my $got_n = $path->xy_to_n ($x, $y);
    ok ($got_n, $want_n, "n at x=$x,y=$y");
  }
}

#------------------------------------------------------------------------------
# xy_to_n() omitted points

{
  my @data = ([ 0,2 ],
              [ 4,0 ],
              [ 0,6 ],
              [ 8,0 ],
              [ 0,10 ],
              [ 12,0 ],
             );
  my $path = Math::PlanePath::StaircaseAlternating->new(end_type=>'square');
  foreach my $elem (@data) {
    my ($x,$y) = @$elem;
    my $got_n = $path->xy_to_n ($x, $y);
    ok (! defined $got_n, 1,
        "square omitted $x,$y");
  }
}

exit 0;
