#!/usr/bin/perl -w

# Copyright 2012, 2013, 2015 Kevin Ryde

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
use Math::Libm 'hypot';
use Math::Trig 'pi','tan';
use Math::PlanePath::MultipleRings;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $path = Math::PlanePath::MultipleRings->new (step => 8,
                                                  ring_shape => 'polygon');
  my $n = 10;
  my ($prev_dx,$prev_dy) = $path->n_to_dxdy($n - 1) or die;
  my ($dx,$dy)           = $path->n_to_dxdy($n)     or die;
  my $LSR = $dy*$prev_dx - $dx*$prev_dy;
  ### $LSR
  if (abs($LSR) < 1e-10) { $LSR = 0; }
  $LSR = ($LSR <=> 0);  # 1,undef,-1
  print "path_n_to_LSR   dxdy $prev_dx,$prev_dy then $dx,$dy  is LSR=$LSR\n";
  exit 0;
}

{
  require Math::NumSeq::PlanePathDelta;
  foreach my $step (3 .. 10) {
    print "$step\n";
    my $path = Math::PlanePath::MultipleRings->new (step => $step,
                                                    ring_shape => 'polygon');
    foreach my $n (0 .. $step-1) {
      my ($dx,$dy) = $path->n_to_dxdy($n+$path->n_start);
      my $dir4 = Math::NumSeq::PlanePathDelta::_delta_func_Dir4($dx,$dy);
      printf "%2d %6.3f,%6.3f  %6.3f\n", $n, $dx,$dy, $dir4;
    }
    # my $m = int((3*$step-3)/4);
# $m = int((2*$step-4)/4);
    my $m = 2*$step - 2 + ($step%2);
    my ($cx,$cy) = Math::PlanePath::MultipleRings::_circlefrac_to_xy
      (1, $m, 2*$step, pi());
    # $cx = -$cx;
    my $dir4 = Math::NumSeq::PlanePathDelta::_delta_func_Dir4($cx,$cy);
    print "$m  $cx, $cy    $dir4\n";
    print "\n";
  }
  exit 0;
}

{
  foreach my $step (0 .. 10) {
    my $path = Math::PlanePath::MultipleRings->new (step => $step,
                                                    ring_shape => 'polygon');
    for (my $n = $path->n_start; $n < 10; $n++) {
      my ($x, $y) = $path->n_to_xy($n);
      my $g = gcd($x,$y);
      printf "%2d %6.3f,%6.3f  %.8g\n", $n, $x,$y, $g;
    }
    print "\n";
  }
  use POSIX 'fmod';
  sub gcd {
    my ($x,$y) = @_;
    $x = abs($x);
    $y = abs($y);
    unless ($x > 0) {
      return $y;
    }
    # if (is_infinite($x)) { return $x; }
    # if (is_infinite($y)) { return $y; }
    if ($y > $x) {
      $y = fmod($y,$x);
    }
    for (;;) {
      ### gcd at: "x=$x y=$y"
      if ($y == 0) {
        return $x;   # gcd(x,0)=x
      }
      if ($y < 0.0001) {
        return 0.00001;
      }
      ($x,$y) = ($y, fmod($x,$y));
    }
  }

  exit 0;
}

{
  require Math::BigFloat;
  # Math::BigFloat->precision(-3);
  my $n = Math::BigFloat->new(4);
  # $n->accuracy(5);
   $n->precision(-3);
  my $pi = Math::PlanePath::MultipleRings::_pi($n);
  print "$pi\n";
  exit 0;
}

{
  my $pi = pi();
  my $offset = 0.0;

  foreach my $step (3,4,5,6,7,8) {
    my $path = Math::PlanePath::MultipleRings->new (step => $step,
                                                    ring_shape => 'polygon');
    my $d = 1;
    my $n0base = Math::PlanePath::MultipleRings::_d_to_n0base($path,$d);
    my $next_n0base = Math::PlanePath::MultipleRings::_d_to_n0base($path,$d+10);

    my ($pbase, $pinc);
    if ($step > 6) {
      $pbase = 0;
      $pinc = Math::PlanePath::MultipleRings::_numsides_to_r($step,$pi);
    } else {
      $pbase = Math::PlanePath::MultipleRings::_numsides_to_r($step,$pi);
      $pinc = 1/cos($pi/$step);
    }
    print "step=$step  pbase=$pbase  pinc=$pinc\n";

    for (my $n = $n0base+$path->n_start; $n < $next_n0base; $n += 1.0) {
      my ($x, $y) = $path->n_to_xy($n);
      my $revn = $path->xy_to_n($x-$offset,$y) // 'undef';
      my $r = hypot ($x, $y);

      my $theta_frac = Math::PlanePath::MultipleRings::_xy_to_angle_frac($x,$y);
      $theta_frac -= int($theta_frac*$step) / $step;  # modulo 1/step

      my $alpha = 2*$pi/$step;
      my $theta = 2*$pi * $theta_frac;
      ### $r
      ### x=r*cos(theta): $r*cos($theta)
      ### y=r*sin(theta): $r*sin($theta)

      my $p = $r*cos($theta) + $r*sin($theta) * sin($alpha/2)/cos($alpha/2);
      $d = ($p - $pbase) / $pinc + 1;

      printf "%5.1f  thetafrac=%.4f  r=%.4f p=%.4f d=%.2f  revn=%s\n",
        $n, $theta_frac, $r, $p, $d, $revn;
      if ($n==int($n) && (! defined $revn || $revn != $n)) {
        print "\n";
        die "oops, revn=$revn != n=$n";
      }
    }
    print "\n";
  }
  exit 0;
}

{
  # dir_minimum_dxdy() position
  require Math::PlanePath::MultipleRings;
  require Math::NumSeq::PlanePathDelta;
  foreach my $step (3 .. 100) {
    my $path = Math::PlanePath::MultipleRings->new (step => $step,
                                                    ring_shape => 'polygon');
    my $min_dir4 = 99;
    my $min_n = 1;
    my $max_dir4 = 0;
    my $max_n = 1;
    foreach my $n (1 .. $step) {
      my ($dx,$dy) = $path->n_to_dxdy($n);
      my $dir4 = Math::NumSeq::PlanePathDelta::_delta_func_Dir4($dx,$dy);
      if ($dir4 > $max_dir4) {
        $max_dir4 = $dir4;
        $max_n = $n;
      }
      if ($dir4 < $min_dir4) {
        $min_dir4 = $dir4;
        $min_n = $n;
      }
    }
    my $min_diff = $step - $min_n;
    my $max_diff = $step - $max_n;
    print "$step  min N=$min_n $min_diff  max N=$max_n $max_diff\n";
  }
  exit 0;
}
{
  # Dir4 minimum, maximum
  require Math::PlanePath::MultipleRings;
  foreach my $step (3 .. 20) {
    my $path = Math::PlanePath::MultipleRings->new (step => $step,
                                                    ring_shape => 'polygon');
    my $min = $path->dir4_minimum();
    my $max = $path->dir4_maximum();
    my $den = 2*$step;
    $min *= $den;
    $max *= $den;
    my $md = 4*$den - $max;
    print "$step   $min  $max($md)   / $den\n";
  }
  exit 0;
}

{
  # polygon pack

  my $poly = 5;

  # w/c = tan(angle/2)
  # w = c*tan(angle/2)

  # (c/row)^2 + (c-prev)^2 = 1
  # 1/row^2 * c^2 + (c^2 - 2cp + p^2) = 1
  # 1/row^2 * c^2 + c^2 - 2cp + p^2 - 1 = 0
  # (1/row^2 + 1) * c^2 - 2p*c + (p^2 - 1) = 0
  # A = (1 + 1/row^2)
  # B = -2p
  # C = (p^2-1)
  # c = (2p + sqrt(4p^2 - 4*(p^2+1)*(1 + 1/row^2))) / (2*(1 + 1/row^2))

  # d = c-prev
  # c = d+prev
  # ((d+prev)/row)^2 + d^2 = 1
  # (d^2+2dp+p^2)/row^2 + d^2 = 1
  # d^2/row^2 + 2p/row^2 * d + p^2/row^2 + d^2 - 1 = 0
  # (1+1/row^2)*d^2 + 2p/row^2 * d + (p^2/row^2 - 1) = 0
  # A = (1+1/row^2)
  # B = 2p/row^2
  # C = (p^2/row^2 - 1)

  my $angle_frac = 1/$poly;
  my $angle_degrees = $angle_frac * 360;
  my $angle_radians = 2*pi * $angle_frac;
  my $slope = 1/cos($angle_radians/2);  # e = slope*c
  my $tan = tan($angle_radians/2);
  print "angle $angle_degrees slope $slope  tan=$tan\n";

  my @c = (0);
  my @e = (0);
  my @points_on_row;

  my $delta_minimum = 1/$slope;
  my $delta_minimum_hypot = hypot($delta_minimum, $delta_minimum*$tan);
  print "delta_minimum = $delta_minimum  (hypot $delta_minimum_hypot)\n";

  # tan a/2 = 0.5/c
  # c = 0.5 / tan(a/2)
  my $c = 0.5 / tan($angle_radians/2);
  my $e = $c * $slope;
  $c[1] = $c;
  $e[1] = $e;
  my $w = $c*$tan;
  print "row=1 initial c=$c  e=$e  w=$w\n";


  {
    my $delta_equil = sqrt(3)/2;
    my $delta_side = cos($angle_radians/2);
    print "  delta equil=$delta_equil side=$delta_side\n";
    if ($delta_equil > $delta_side) {
      $c += $delta_equil;
      $w = $c*$tan;
      print "row=2 equilateral to c=$c  w=$w\n";
    } else {
      $c += $delta_side;
      $w = $c*$tan;
      print "row=2 side to c=$c  w=$w\n";
    }
  }
  $e = $c * $slope;
  $c[2] = $c;
  $e[2] = $e;

  # for (my $row = 3; $row < 27; $row += 2) {
  #   my $p = $c;
  #
  #   # # (p - (row-2)/row * c)^2 + (c-p)^2 = 1
  #   # # p^2 - 2*rf*p*c + rf^2*c^2 + c^2 - 2cp + p^2 - 1 = 0
  #   # # rf^2*c^2 + c^2 - 2*rf*p*c - 2*p*c + p^2 + p^2 - 1 = 0
  #   # # (rf^2 + 1)*c^2 + (- 2*rf*p - 2*p)*c + (p^2 + p^2 - 1) = 0
  #   # # (rf^2 + 1)*c^2 + -2*p*(rf+1)*c + (p^2 + p^2 - 1) = 0
  #   # #
  #   # my $rf = ($row-2)/$row;
  #   # my $A = ($rf^2 + 1);
  #   # my $B = -2*$rf*$p - 2*$p;
  #   # my $C = (2*$p**2 - 1);
  #   # print "A=$A B=$B C=$C\n";
  #   # my $next_c;
  #   # my $delta;
  #   # if ($B*$B - 4*$A*$C >= 0) {
  #   #   $next_c = (-$B + sqrt($B*$B - 4*$A*$C))/(2*$A);
  #   #   $delta = $next_c - $c;
  #   # } else {
  #   #   $delta = .7;
  #   #   $next_c = $c + $delta;
  #   #
  #   #   my $side = ($c - $rf*$next_c);
  #   #   my $h = hypot($side, $delta);
  #   #   print "  h=$h\n";
  #   # }
  #
  #   # delta of i=0 j=1
  #   #
  #   # (p - (row-2)/row * c)^2 + d^2 = 1
  #   # (p - rf*(p+d))^2 + d^2 = 1
  #   # (p - rf*p - rf*d))^2 + d^2 = 1
  #   # (-p + rf*p + rf*d))^2 + d^2 = 1
  #   # (rf*d -p + rf*p)^2 + d^2 = 1
  #   # (rf*d + (rf-1)p)^2 + d^2 = 1
  #   # rf^2*d^2 + 2*rf*(rf-1)*p * d + (rf-1)^2*p^2 + d^2 - 1 = 0
  #   # (rf^2+1)*d^2 + rf*(rf-1)*p * d + ((rf-1)^2*p^2 - 1) = 0
  #   #
  #   my $rf = ($row-2)/$row;
  #    $rf = ($row+1 -2)/($row+1);
  #   my $A = $rf**2 + 1;
  #   my $B = 2*$rf*($rf-1)*$p;
  #   my $C = ($rf-1)**2 * $p**2 - 1;
  #   my $delta;
  #   if ($B*$B - 4*$A*$C >= 0) {
  #     $delta = (-$B + sqrt($B*$B - 4*$A*$C))/(2*$A);
  #   } else {
  #     print "discrim: ",$B*$B - 4*$A*$C,"\n";
  #     $delta = 0;
  #   }
  #
  #   # delta of i=0 j=0
  #   # (c - p)^2 + d^2 = 1
  #   #
  #   if ($delta < $delta_minimum+.0) {
  #     print "  side minimum $delta < $delta_minimum\n";
  #     $delta = $delta_minimum;
  #   }
  #   my $next_c = $delta + $c;
  #
  #
  #   # my $A = (1 + ($tan/$row)**2);
  #   # my $B = -2*$c;
  #   # my $C = ($c**2 - 1);
  #   # my $next_c = (-$B + sqrt($B*$B - 4*$A*$C))/(2*$A);
  #   # my $delta = $next_c - $c;
  #   #
  #   # $A = (1 + ($tan/$row)**2);
  #   # $B = 2*$c/$row**2;
  #   # $C = ($c**2/$row**2 - 1);
  #   # my $delta_2 = 0; # (-$B + sqrt($B*$B - 4*$A*$C))/(2*$A);
  #   # printf "row=$row delta=%.5f=%.5f next_c=%.5f\n", $delta, $delta_2, $next_c;
  #   printf "row=$row delta=%.5f next_c=%.5f\n", $delta, $next_c;
  #
  #   $c[$row] = $c + $delta;
  #   $c[$row+1] = $c + 2*$delta;
  #
  #   $e[$row] = $c[$row] * $slope;
  #   $e[$row+1] = $c[$row+1] * $slope;
  #
  #   $c += 2*$delta;
  # }

  for (my $row = 3; $row < 138; $row++) {
    my $p = $c;

    # # (p - (row-2)/row * c)^2 + (c-p)^2 = 1
    # # p^2 - 2*rf*p*c + rf^2*c^2 + c^2 - 2cp + p^2 - 1 = 0
    # # rf^2*c^2 + c^2 - 2*rf*p*c - 2*p*c + p^2 + p^2 - 1 = 0
    # # (rf^2 + 1)*c^2 + (- 2*rf*p - 2*p)*c + (p^2 + p^2 - 1) = 0
    # # (rf^2 + 1)*c^2 + -2*p*(rf+1)*c + (p^2 + p^2 - 1) = 0
    # #
    # my $rf = ($row-2)/$row;
    # my $A = ($rf^2 + 1);
    # my $B = -2*$rf*$p - 2*$p;
    # my $C = (2*$p**2 - 1);
    # print "A=$A B=$B C=$C\n";
    # my $next_c;
    # my $delta;
    # if ($B*$B - 4*$A*$C >= 0) {
    #   $next_c = (-$B + sqrt($B*$B - 4*$A*$C))/(2*$A);
    #   $delta = $next_c - $c;
    # } else {
    #   $delta = .7;
    #   $next_c = $c + $delta;
    #
    #   my $side = ($c - $rf*$next_c);
    #   my $h = hypot($side, $delta);
    #   print "  h=$h\n";
    # }

    # delta of i=0 j=1
    #
    # (p*tan - (row-2)/row * tan*c)^2 + d^2 = 1
    # tt*(p - rf*(p+d))^2 + d^2 = 1
    # tt*(p - rf*p - rf*d)^2 + d^2 = 1
    # tt*(-p + rf*p + rf*d)^2 + d^2-1 = 0
    # tt*(rf*d -p + rf*p)^2 + d^2-1 = 0
    # tt*(rf*d + (rf-1)p)^2 + d^2-1 = 0
    # tt*rf^2*d^2 + tt*2*rf*(rf-1)*p * d + tt*(rf-1)^2*p^2 + d^2 - 1 = 0
    # (tt*rf^2+1)*d^2 + tt*rf*(rf-1)*p * d + (tt*(rf-1)^2*p^2 - 1) = 0
    #
    #    print "  rf ",($row-2),"/$row\n";
    my $rf = ($row-2)/($row);
    my $A = $tan**2 * $rf**2 + 1;
    my $B = $tan**2 * 2*$rf*($rf-1)*$p;
    my $C = $tan**2 * ($rf-1)**2 * $p**2 - 1;
    my $delta;
    if ($B*$B - 4*$A*$C >= 0) {
      $delta = (-$B + sqrt($B*$B - 4*$A*$C))/(2*$A);
      my $next_c = $delta + $c;
      my $pw = $p * $tan;
      my $next_w = $next_c * $tan;
      my $rem = $pw - $next_w*($row-2)/$row;
      my $h = hypot ($delta, $rem);
      #     print "  h^2=$h  pw=$pw nw=$next_w rem=$rem\n";
    } else {
      print "discrim: ",$B*$B - 4*$A*$C,"\n";
      my $w = $p*$tan / $row;
      print "  at d=0 w=$w\n";
      $delta = 0;
    }

    # delta of i=0 j=0
    # (c - p)^2 + d^2 = 1
    #
    if ($delta < $delta_minimum+.0) {
      print "  side minimum $delta < $delta_minimum\n";
      $delta = $delta_minimum;
    }
    my $next_c = $delta + $c;

    printf "row=$row delta=%.5f next_c=%.5f\n", $delta, $next_c;

    $c += $delta;
    $c[$row] = $c;
    $e[$row] = $c[$row] * $slope;
  }
  # print "c ",join(', ',@c),"\n";
  # print "e ",join(', ',@e),"\n";


  my (@x,@y);
  foreach my $row (1 .. $#c) {
    my $x1 = $e[$row];
    my $y1 = 0;
    my ($x2,$y2) = Math::Trig::cylindrical_to_cartesian($e[$row],
                                                        $angle_radians, 0);
    my $dx = $x2-$x1;
    my $dy = $y2-$y1;

    foreach my $p (0 .. $row) {
      $x[$row][$p] = $x1 + $dx*$p/$row;
      $y[$row][$p] = $y1 + $dy*$p/$row;
    }
    # print "row=$row x ",join(', ',@{$x[$row]}),"\n";
  }

  foreach my $row (1 .. $#c-1) {
    print "\n";
    my $min_dist = 9999;
    my $min_dist_at_i = -1;
    my $min_dist_at_j = -1;
    foreach my $i (0 .. $row) {
      foreach my $j (0 .. $row+1) {
        my $dist = hypot($x[$row][$i] - $x[$row+1][$j],
                         $y[$row][$i] - $y[$row+1][$j]);
        if ($dist < $min_dist) {
          # print "  dist=$dist at i=$i j=$j\n";
          $min_dist = $dist;
          $min_dist_at_i = $i;
          $min_dist_at_j = $j;
        }
      }
    }
    if ($min_dist_at_i > $row/2) {
      $min_dist_at_i = $row - $min_dist_at_i;
      $min_dist_at_j = $row+1 - $min_dist_at_j;
    }
    print "row=$row  min_dist=$min_dist at i=$min_dist_at_i j=$min_dist_at_j\n";
    my $zdist = hypot($x[$row][0] - $x[$row+1][0],
                      $y[$row][0] - $y[$row+1][0]);
    my $odist = hypot($x[$row][0] - $x[$row+1][1],
                      $y[$row][0] - $y[$row+1][1]);
    print "  zdist=$zdist  odist=$odist\n";
  }


  open OUT, '>', '/tmp/multiple-rings.tmp' or die;
  foreach my $row (1 .. $#c-1) {
    foreach my $i (0 .. $row) {
      print OUT "$x[$row][$i], $y[$row][$i]\n";
    }
  }
  close OUT or die;

  system ('math-image --wx --path=File,filename=/tmp/multiple-rings.tmp --all --scale=25 --figure=ring');

  exit 0;
}

{
  # max dx

  require Math::PlanePath::MultipleRings;
  my $path = Math::PlanePath::MultipleRings->new (step => 37);
  my $n = $path->n_start;
  my $dx_max = 0;
  my ($prev_x, $prev_y) = $path->n_to_xy($n++);
  foreach (1 .. 1000000) {
    my ($x, $y) = $path->n_to_xy($n++);

    my $dx = $y - $prev_y;
    if ($dx > $dx_max) {
      print "$n  $dx\n";
      $dx_max = $dx;
    }

    $prev_x = $x;
    $prev_y = $y;
  }
  exit 0;
}
