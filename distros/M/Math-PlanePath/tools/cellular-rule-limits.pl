#!/usr/bin/perl -w

# Copyright 2013, 2014 Kevin Ryde

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


use 5.010;
use strict;
use List::Util 'min', 'max';
use Math::PlanePath::CellularRule;

# uncomment this to run the ### lines
# use Smart::Comments;

my %h;
use Tie::IxHash;
tie %h, 'Tie::IxHash';

foreach my $rule (# 141,
                  0 .. 255,
                 ) {
  print "$rule\n";
  my $path = Math::PlanePath::CellularRule->new(rule=>$rule);
  unless (ref $path eq 'Math::PlanePath::CellularRule') {
    ### skip subclass: ref $path
    next;
  }

  my @x;
  my @y;
  my @sumxy;
  my @diffxy;
  my $x_negative_at_n;

  my @dx;
  my @dy;
  my @dsumxy;
  my @ddiffxy;

  my $n_start = $path->n_start;
  foreach my $n ($n_start .. 200) {
    my ($x,$y) = $path->n_to_xy($n)
      or last;
    ### at: "n=$n  xy=$x,$y"

    push @x, $x;
    push @y, $y;
    push @sumxy, $x+$y;
    push @diffxy, $x-$y;
    if ($x < 0 && ! defined $x_negative_at_n) {
      $x_negative_at_n = $n - $n_start;
      ### $x_negative_at_n
    }

    if (my ($dx,$dy) = $path->n_to_dxdy($n)) {
      push @dx, $dx;
      push @dy, $dy;
      push @dsumxy, $dx+$dy;
      push @ddiffxy, $dx-$dy;
    }
  }

  $h{'x_minimum'}->[$rule] = min(@x);
  $h{'x_maximum'}->[$rule] = max(@x);
  $h{'y_maximum'}->[$rule] = max(@y);
  ### $x_negative_at_n
  $h{'x_negative_at_n'}->[$rule] = $x_negative_at_n;

  $h{'dx_minimum'}->[$rule] = min(@dx);
  $h{'dx_maximum'}->[$rule] = max(@dx);
  $h{'dy_minimum'}->[$rule] = min(@dy);
  $h{'dy_maximum'}->[$rule] = max(@dy);

  $h{'absdx_minimum'}->[$rule] = min(map{abs}@dx);
  $h{'absdx_maximum'}->[$rule] = max(map{abs}@dx);
  $h{'absdy_minimum'}->[$rule] = min(map{abs}@dy);

  $h{'sumxy_minimum'}->[$rule] = min(@sumxy);
  $h{'sumxy_maximum'}->[$rule] = max(@sumxy);
  $h{'diffxy_minimum'}->[$rule] = min(@diffxy);
  $h{'diffxy_maximum'}->[$rule] = max(@diffxy);

  $h{'dsumxy_minimum'}->[$rule] = min(@dsumxy);
  $h{'dsumxy_maximum'}->[$rule] = max(@dsumxy);
  $h{'ddiffxy_minimum'}->[$rule] = min(@ddiffxy);
  $h{'ddiffxy_maximum'}->[$rule] = max(@ddiffxy);
}

foreach my $name (keys %h,
                  # 'x_negative_at_n',
                 ) {
  print "  my \@${name} = (\n";
  my $aref = $h{$name};
  while (@$aref && ! defined $aref->[-1]) {
    pop @$aref;
  }
  my $row_rule;
  foreach my $rule (0 .. $#$aref) {
    if ($rule % 8 == 0) {
      print "    ";
      $row_rule = $rule;
    }
    my $value = $aref->[$rule];
    if (defined $value && $name ne 'x_negative_at_n' && ($value < -5 || $value > 5)) { $value = undef; }
    if (! defined $value) { $value = 'undef'; }
    printf " %5s,", $value;
    if ($rule % 8 == 7 || $rule == $#$aref) { print "    # rule=$row_rule\n"; }
  }
}

exit 0;




__END__

my @dx_minimum = (
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef,    -2, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef,    -2, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef,     0, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef,     0, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef,    -2, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef,    -2, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef,     0, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef, undef, undef,
                  undef, undef, undef, undef,     0, undef, undef, undef,
                  undef, undef, undef, undef, undef, undef,

                  my @dy_maximum = (
                                    undef,     2, undef,     1, undef,     1, undef,     2,
                                    undef,     2, undef,     1, undef,     1,     1,     1,
                                    undef,     1, undef,     2, undef,     2,     1,     2,
                                    undef,     1, undef,     1,     1,     1,     1,     2,
                                    undef,     2, undef,     1, undef,     1, undef,     1,
                                    undef,     2, undef,     1, undef,     1,     1,     1,
                                    undef,     1, undef,     1, undef,     1, undef,     2,
                                    undef, undef, undef,     1, undef,     1,     1,     2,
                                    undef,     2, undef,     1, undef,     1,     1,     1,
                                    undef,     2, undef,     1, undef,     1,     1,     1,
                                    undef,     1, undef,     1,     1,     1,     1,     2,
                                    undef,     1, undef,     1,     1,     1,     1,     2,
                                    undef,     2, undef, undef, undef,     1, undef,     1,
                                    undef,     2, undef,     1, undef,     1,     1,     1,
                                    undef,     1, undef,     1,     1,     1,     1,     2,
                                    undef,     1, undef,     1,     1,     1,     1,     2,
                                    undef,     2, undef,     1, undef,     1, undef,     1,
                                    undef,     2, undef,     1, undef,     1,     1,     1,
                                    undef,     1, undef,     1, undef,     1,     1, undef,
                                    undef,     1, undef,     1,     1,     1,     1, undef,
                                    undef,     2, undef,     1, undef,     1, undef,     1,
                                    undef,     2, undef,     1, undef,     1,     1,     1,
                                    undef,     1, undef, undef, undef,     1,     1, undef,
                                    undef,     1, undef,     1,     1,     1, undef, undef,
                                    undef,     2, undef,     1, undef,     1,     1,     1,
                                    undef,     2, undef,     1, undef,     1, undef,     1,
                                    undef,     1, undef,     1,     1,     1,     1, undef,
                                    undef,     1, undef,     1, undef,     1, undef, undef,
                                    undef,     2, undef,     1, undef,     1,     1,     1,
                                    undef,     2, undef,     1, undef,     1, undef,     1,
                                    undef,     1, undef,     1,     1,     1, undef, undef,
                                    undef,     1, undef,     1, undef,     1,

                                    my @absdy_minimum = (
                                                         undef,     0, undef,     0, undef,     0, undef,     0,
                                                         undef,     0, undef,     0, undef,     0,     0,     0,
                                                         undef,     0, undef,     0, undef,     0,     0,     0,
                                                         undef,     0, undef,     0,     0,     0,     0,     0,
                                                         undef,     0, undef,     0, undef,     0, undef,     0,
                                                         undef,     0, undef,     0, undef,     0,     0,     0,
                                                         undef,     0, undef,     0, undef,     0, undef,     0,
                                                         undef, undef, undef,     0, undef,     0,     0,     0,
                                                         undef,     0, undef,     0, undef,     0,     0,     0,
                                                         undef,     0, undef,     0, undef,     0,     0,     0,
                                                         undef,     0, undef,     0,     0,     0,     0,     0,
                                                         undef,     0, undef,     0,     0,     0,     0,     0,
                                                         undef,     0, undef, undef, undef,     0, undef,     0,
                                                         undef,     0, undef,     0, undef,     0,     0,     0,
                                                         undef,     0, undef,     0,     0,     0,     0,     0,
                                                         undef,     0, undef,     0,     0,     0,     0,     0,
                                                         undef,     0, undef,     0, undef,     0, undef,     0,
                                                         undef,     0, undef,     0, undef,     0,     0,     0,
                                                         undef,     0, undef,     0, undef,     0,     0, undef,
                                                         undef,     0, undef,     0,     0,     0,     0, undef,
                                                         undef,     0, undef,     0, undef,     0, undef,     0,
                                                         undef,     0, undef,     0, undef,     0,     0,     0,
                                                         undef,     0, undef, undef, undef,     0,     0, undef,
                                                         undef,     0, undef,     0,     0,     0, undef, undef,
                                                         undef,     0, undef,     0, undef,     0,     0,     0,
                                                         undef,     0, undef,     0, undef,     0, undef,     0,
                                                         undef,     0, undef,     0,     0,     0,     0, undef,
                                                         undef,     0, undef,     0, undef,     0, undef, undef,
                                                         undef,     0, undef,     0, undef,     0,     0,     0,
                                                         undef,     0, undef,     0, undef,     0, undef,     0,
                                                         undef,     0, undef,     0,     0,     0, undef, undef,
                                                         undef,     0, undef,     0, undef,     0,

                                                         my @sum_maximum = (
                                                                            0, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef,     1, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef,     1, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef, undef, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef, undef, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef,     1, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef,     1, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef, undef, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef, undef, undef,
                                                                            0, undef, undef, undef, undef, undef, undef, undef,
                                                                            undef, undef, undef, undef, undef, undef, undef, undef,
                                                                            undef, undef, undef, undef, undef, undef,
                                                                            my @diff_maximum = (
                                                                                                0,     0, undef,     0, undef,     0, undef,     0,
                                                                                                0,     0, undef,     0, undef,     0,     0,     0,
                                                                                                undef,     0, undef,     0, undef,     0,     0,     0,
                                                                                                undef,     0, undef,     0,     0,     0,     0,     0,
                                                                                                0,     0, undef,     0, undef,     0, undef,     0,
                                                                                                0,     0, undef,     0, undef,     0,     0,     0,
                                                                                                undef,     0, undef,     0, undef,     0, undef,     0,
                                                                                                undef, undef, undef,     0, undef,     0,     0,     0,
                                                                                                0,     0, undef,     0, undef,     0,     0,     0,
                                                                                                0,     0, undef,     0, undef,     0,     0,     0,
                                                                                                undef,     0, undef,     0,     0,     0,     0,     0,
                                                                                                undef,     0, undef,     0,     0,     0,     0,     0,
                                                                                                0,     0, undef, undef, undef,     0, undef,     0,
                                                                                                0,     0, undef,     0, undef,     0,     0,     0,
                                                                                                undef,     0, undef,     0,     0,     0,     0,     0,
                                                                                                undef,     0, undef,     0,     0,     0,     0,     0,
                                                                                                0,     0, undef,     0, undef,     0, undef,     0,
                                                                                                0,     0, undef,     0, undef,     0,     0,     0,
                                                                                                undef,     0, undef,     0, undef,     0,     0, undef,
                                                                                                undef,     0, undef,     0,     0,     0,     0, undef,
                                                                                                0,     0, undef,     0, undef,     0, undef,     0,
                                                                                                0,     0, undef,     0, undef,     0,     0,     0,
                                                                                                undef,     0, undef, undef, undef,     0,     0, undef,
                                                                                                undef,     0, undef,     0,     0,     0, undef, undef,
                                                                                                0,     0, undef,     0, undef,     0,     0,     0,
                                                                                                0,     0, undef,     0, undef,     0, undef,     0,
                                                                                                undef,     0, undef,     0,     0,     0,     0, undef,
                                                                                                undef,     0, undef,     0, undef,     0, undef, undef,
                                                                                                0,     0, undef,     0, undef,     0,     0,     0,
                                                                                                0,     0, undef,     0, undef,     0, undef,     0,
                                                                                                undef,     0, undef,     0,     0,     0, undef, undef,
                                                                                                undef,     0, undef,     0, undef,     0,
                                                                                                my @dsum_minimum = (
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef,    -1, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef,    -1, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef,     1, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef,     1, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef,    -1, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef,    -1, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef,     1, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef,     1, undef, undef, undef,
                                                                                                                    undef, undef, undef, undef, undef, undef,
                                                                                                                    my @ddiffxy_minimum = (
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef,    -3, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef,    -3, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef,    -1, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef,    -1, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef,    -3, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef,    -3, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef,    -1, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef,    -1, undef, undef, undef,
                                                                                                                                           undef, undef, undef, undef, undef, undef,
