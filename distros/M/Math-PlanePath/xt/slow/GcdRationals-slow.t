#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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
use List::Util 'min','max';
use Test;
plan tests => 637;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::GcdRationals;
my @pairs_order_choices
  = @{Math::PlanePath::GcdRationals->parameter_info_hash
      ->{'pairs_order'}->{'choices'}};


#------------------------------------------------------------------------------
# rect_to_n_range()

my $bad = 0;

my $y_min = 1;
my $y_max = 50;
my $x_min = 1;
my $x_max = 50;

foreach my $pairs_order (@pairs_order_choices) {
  my $path = Math::PlanePath::GcdRationals->new (pairs_order => $pairs_order);
  my $n_start = $path->n_start;

  my $report = sub {
    MyTestHelpers::diag("$pairs_order ",@_);
    $bad++;
  };

  my %data;
  my $data_count;
  foreach my $x ($x_min .. $x_max) {
    foreach my $y ($y_min .. $y_max) {
      my $n = $path->xy_to_n ($x, $y);
      $data{$y}{$x} = $n;
      $data_count += defined $n;
    }
  }
  MyTestHelpers::diag("$pairs_order data_count ",$data_count);

  foreach my $y1 ($y_min .. $y_max) {
    foreach my $y2 ($y1 .. $y_max) {

      foreach my $x1 ($x_min .. $x_max) {
        my $min;
        my $max;

        foreach my $x2 ($x1 .. $x_max) {
          my @col = map {$data{$_}{$x2}} $y1 .. $y2;
          @col = grep {defined} @col;
          $min = min (grep {defined} $min, @col);
          $max = max (grep {defined} $max, @col);
          my $want_min = (defined $min ? $min : 1);
          my $want_max = (defined $max ? $max : 0);
          ### @col
          ### rect: "$x1,$y1  $x2,$y2  expect N=$want_min..$want_max"

          my ($got_min, $got_max)
            = $path->rect_to_n_range ($x1,$y1, $x2,$y2);
          defined $got_min
            or &$report ("rect_to_n_range($x1,$y1, $x2,$y2) got_min undef");
          defined $got_max
            or &$report ("rect_to_n_range($x1,$y1, $x2,$y2) got_max undef");
          $got_min >= $n_start
            or &$report ("rect_to_n_range() got_min=$got_min is before n_start=$n_start");

          if (! defined $min || ! defined $max) {
            next; # outside
          }

          unless ($got_min <= $want_min) {
            ### $x1
            ### $y1
            ### $x2
            ### $y2
            ### got: $path->rect_to_n_range ($x1,$y1, $x2,$y2)
            ### $want_min
            ### $want_max
            ### $got_min
            ### $got_max
            ### @col
            ### $data
            &$report ("rect_to_n_range($x1,$y1, $x2,$y2) bad min  got_min=$got_min want_min=$want_min".(defined $min ? '' : '[nomin]')
                     );
          }
          unless ($got_max >= $want_max) {
            &$report ("rect_to_n_range($x1,$y1, $x2,$y2 ) bad max got $got_max want $want_max".(defined $max ? '' : '[nomax]'));
          }
        }
      }
    }
  }
}

ok ($bad, 0);

#------------------------------------------------------------------------------
exit 0;
