#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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
use Math::Libm 'hypot', 'asinh', 'M_PI', 'asin';
use POSIX ();
use Math::PlanePath::Base::Generic 'round_nearest';
use Math::PlanePath::ArchimedeanChords;

# uncomment this to run the ### lines
use Smart::Comments;

# set term x
# plot [0:50] asinh(x),exp(log(x)*.4)



{
  for (my $r = 1; $r < 1e38; $r *= 1.1) {
    my $theta = $r * 2*M_PI();
    my $arc = spiral_arc_length($theta);
    my $circle = r_to_circles_arclength($r);
    # $circle = ($r*$r+1)*M_PI;  # maybe

    printf "%2d %10.3g %10.3g   %.3f\n",
      $r,
        $circle,
          $arc,
            ($circle<$arc);
  }
  exit 0;
}




# 1/4pi * (t * sqrt(1+t^2) + log(t+sqrt(1+t^2)))
#
# sqrt(1+t^2) <= t + 1/(2*t)
#
# 1/4pi * (t * sqrt(1+t^2) + asinh(t))
#   <= 1/4pi * (t*(t+1/2t) + asinh(t))
#   = 1/4pi * (2pi*r * (2pi*r+ 1/(4pi*r)) + asinh(2pi*r))
#   = 1/2 * r * (2pi*r + 1/(4pi*r)) + 1/4pi * asinh(2pi*r))
#   = pi * r * (r + 1/(8pi^2*r)) + 1/4pi * asinh(2pi*r))
#   = pi * (r^2 + 1/8pi^2*r) + 1/4pi * asinh(2pi*r))

{
  sub r_to_circles_arclength {
    my ($r) = @_;
    return M_PI()*$r*($r+1);
  }
  sub spiral_arc_length {
    my ($theta) = @_;  # theta in radians
    return (1/(4*M_PI())) * ($theta * sqrt(1+$theta**2) + asinh($theta));

    # with $a = 1/2pi for unit spacing
    # return 0.5 * $a * ($theta * sqrt(1+$theta**2) + asinh($theta));
  }
  sub total_chords {
    my ($r) = @_;
    my $sum = 0;
    foreach my $i (2 .. POSIX::ceil($r)) {
      $sum += circle_chords($i);
    }
    return $sum;
  }

  my $a = 1 / (2*M_PI());
  print "a=$a\n";
  print "r=",(2*M_PI)*$a,"\n";
  for (my $r = 1; $r < 1e38; $r *= 1.5) {

    my $theta = $r * 2*M_PI();
    my $arc = spiral_arc_length($theta);
    my $circle = r_to_circles_arclength($r);
     $circle = ($r*$r+1)*M_PI;
    my $chords = total_chords($r-1);

    printf "%2d %10.3g %10.3g %10.3g   %.3f\n",
      $r,
        $chords,
          $circle,
            $arc,
              ($circle-$arc)/$r;
  }
  exit 0;
}

{
  require Math::Polynomial;
  require Math::BigRat;
  my $asin = Math::Polynomial->new (map
                                    # {Math::BigRat->new($_)}
                                    {eval $_}
                                    0, 1,
                                    0, '1/6',
                                    0, '3/40',
                                    0, '5/112',
                                    0, '35/1152');
  $asin->string_config({ascending=>1});
  print "$asin\n";

  my $r2 = $asin->new (0, 0.5);
  my $den = $asin->nest($r2);
  print "$den\n";

  my $num = $asin->monomial(1);
  foreach (1 .. 40) {
    (my $q, $num) = $num->divmod($den);
    print "q=$q\n";
    $num = $num->shift_up(1);
  }

  exit 0;
}



{
  sub circle_chords {
    my ($r) = @_;
    return M_PI() / asin(0.5/$r);
  }
  for (my $r = 1; $r < 100; $r++) {
    my $chords = circle_chords($r);
    printf "%2d %8.3g\n",
      $r, $chords;
  }
  exit 0;
}

{
  my $path = Math::PlanePath::ArchimedeanChords->new;
  my $prev_x = 1;
  my $prev_n = 0;
  my $i = 0;
  foreach my $n ($path->n_start .. 100000) {
    my ($x, $y) = $path->n_to_xy ($n);
    if ($x > 0 && $prev_x < 0) {
      $i++;
      my $diff = $n - $prev_n;
      my $avg = $diff / $i;
      print "$n  $diff   $avg\n";
      $prev_n = $n;
    }
    $prev_x = $x;
  }
  exit 0;
}


{
  require Math::PlanePath::ArchimedeanChords;
  require Math::PlanePath::TheodorusSpiral;
  require Math::PlanePath::VogelFloret;
  #my $path = Math::PlanePath::VogelFloret->new;
  my $path = Math::PlanePath::ArchimedeanChords->new;
  ### $path
  my $n = $path->xy_to_n (600, 0);
  ### $n
 $n = $path->xy_to_n (600, 0);
  ### $n
  exit 0;
}

{
  require Math::Symbolic;
  use Math::Symbolic::Derivative;
  my $tree = Math::Symbolic->parse_from_string(
                                               # '(t*cos(t)-c)^2'
                                               # '(t*sin(t)-s)'
                                               # '(t+1)^2'
                                               # '(t+u)^2 + t^2'
                                               '(t+u)*cos(u)'
                                              );
  # my $tree = Math::Symbolic->parse_from_string();
  print "$tree\n";
  my $derived = Math::Symbolic::Derivative::total_derivative($tree, 'u');
   $derived = $derived->simplify;
  print "$derived\n";

  exit 0;
}


# sub _chord_length {
#   my ($t1, $t2) = @_;
#   my $hyp = hypot(1,$theta);
#   return 0.5 * _A * ($theta*$hyp + asinh($theta));
# }

sub step {
  my ($x, $y) = @_;
  my $r = hypot($x,$y);
  my $len = 1/$r;
  my ($x2, $y2);
  foreach (1 .. 5) {
    ($x2,$y2) = ($x - $y*$len, $y + $x*$len);
    # atan($y2,$x2)
    my $f = hypot($x-$x2, $y-$y2);
    $len /= $f;
    ### maybe: "$x2,$y2 $f"
  }
  return ($x2, $y2);
}

sub next_t {
  my ($t1, $prev_dt) = @_;

  my $t = $t1;
  # my $c1 = $t1 * cos($t1);
  # my $s1 = $t1 * sin($t1);
  # my $c1_2 = $c1*2;
  # my $s1_2 = $s1*2;
  # my $t1sqm = $t1*$t1 - 4*M_PI()*M_PI();

  my $u = 2*M_PI()/$t;
  printf "estimate u=%.6f\n", $u;

  foreach (0 .. 10) {
    # my $slope = 2*($t + (-$c1-$s1*$t)*cos($t) + ($c1*$t-$s1)*sin($t));

    # my $f = ( ($t*cos($t) - $c1) ** 2
    #           + ($t*sin($t) - $s1) ** 2
    #           - 4*M_PI()*M_PI() );
    # my $slope = (2*($t*cos($t)-$c1)*(cos($t) - $t*sin($t))
    #          + 2*($t*sin($t)-$s1)*(sin($t) + $t*cos($t)));

    my $f = ($t+$u)**2 + $t**2 - 2*$t*($t+$u)*cos($u) - 4*M_PI()*M_PI();
    my $slope = 2 * ( $t*(1-cos($u)) + $u + $t*($t+$u)*sin($u) );
    my $sub = $f/$slope;
    $u -= $sub;

    # my $ct = cos($t);
    # my $st = sin($t);
    # my $f = (($t - $ct*$c1_2 - $st*$s1_2) * $t + $t1sqm);
    # my $slope = 2 * (($t*$ct - $c1) * ($ct - $t*$st)
    #                  + ($t*$st - $s1) * ($st + $t*$ct));
    # my $sub = $f/$slope;
    # $t -= $sub;

    last if ($sub < 1e-15);
    printf ("h=%.6f d=%.6f sub=%.20f u=%.6f\n", $slope, $f, $sub, $u);
  }

  return $t + $u;
}
{
  my $t = 2*M_PI;
  my $prev_dt = 1;
  my $prev_x = 1;
  my $prev_y = 0;

  foreach (1 .. 50) {
    my $nt = next_t($t,$prev_dt);
    my $prev_dt = $nt - $t;
    $t = $nt;
    my $r = $t * (1 / (2*M_PI()));
    my $x = $r*cos($t);
    my $y = $r*sin($t);
    my $d = hypot($x-$prev_x, $y-$prev_y);
    my $pdest = 2*M_PI()/$t;
    printf "%d t=%.6f  d=%.3g    pdt=%.3f/%.3f\n",
      $_, $t, $d-1, $prev_dt, $pdest;

    $prev_x = $x;
    $prev_y = $y;
  }
  exit 0;
}

{
  my $t1 = 1 * 2*M_PI;
  my $t = $t1;
  my $r1 = $t / (2*M_PI);
  my $c = cos($t);
  my $s = sin($t);
  my $c1 = $t1 * cos($t1);
  my $s1 = $t1 * sin($t1);
  my $c1_2 = $c1*2;
  my $s1_2 = $s1*2;
  my $t1sqm = $t1*$t1 - 4*M_PI()*M_PI();
  my $x1 = $r1*cos($t1);
  my $y1 = $r1*sin($t1);
  print "x1=$x1 y1=$y1\n";

  $t += 1;
  # {
  #   my $r2 = $t / (2*M_PI);
  #   my $dist = ($t1*cos($t1) - $t*cos($t) ** 2
  #            + ($t1*sin($t1) - $t*sin($t)) ** 2
  #            - 4*M_PI()*M_PI());
  #   my $slope = (2*($t*cos($t)-$c1)*(cos($t) - $t*sin($t))
  #                + 2*($t*sin($t)-$s1)*(sin($t) + $t*cos($t)));
  #   # my $slope = 2*($t + (-$c1-$s1*$t)*cos($t) + ($c1*$t-$s1)*sin($t));
  #   printf "d=%.6f slope=%.6f 1/slope=%.6f\n", $dist, $slope, 1/$slope;
  # }

  foreach (0 .. 10) {
    # my $slope = 2*($t + (-$c1-$s1*$t)*cos($t) + ($c1*$t-$s1)*sin($t));

    # my $dist = ( ($t*cos($t) - $c1) ** 2
    #           + ($t*sin($t) - $s1) ** 2
    #           - 4*M_PI()*M_PI() );
    # my $slope = (2*($t*cos($t)-$c1)*(cos($t) - $t*sin($t))
    #          + 2*($t*sin($t)-$s1)*(sin($t) + $t*cos($t)));

    my $ct = cos($t);
    my $st = sin($t);
    my $dist = (($t - $ct*$c1_2 - $st*$s1_2) * $t + $t1sqm);
    my $slope = 2 * (($t*$ct - $c1) * ($ct - $t*$st)
                     + ($t*$st - $s1) * ($st + $t*$ct));

    my $sub = $dist/$slope;
    $t -= $sub;
    printf ("h=%.6f d=%.6f sub=%.20f t=%.6f\n", $slope, $dist, $sub, $t);
  }

  my $r2 = $t / (2*M_PI);
  my $x2 = $r2 * cos($t);
  my $y2 = $r2 * sin($t);
  my $dist = hypot ($x1-$x2, $y1-$y2);

  printf ("d=%.6f dt=%.6f\n", $dist, $t - $t1);
  exit 0;
}


{
  my ($x, $y) = (1, 0);
  foreach (1 .. 3) {
    step ($x, $y);
    ### step to: "$x, $y"
  }
  exit 0;
}



{
  my $width = 79;
  my $height = 40;
  my $x_scale = 3;
  my $y_scale = 2;

  my $y_origin = int($height/2);
  my $x_origin = int($width/2);

  my $path = Math::PlanePath::ArchimedeanChords->new;
  my @rows = (' ' x $width) x $height;

  foreach my $n (0 .. 60) {
    my ($x, $y) = $path->n_to_xy ($n) or next;
    $x *= $x_scale;
    $y *= $y_scale;

    $x += $x_origin;
    $y = $y_origin - $y;  # inverted

    $x -= length($n) / 2;
    $x = round_nearest ($x);
    $y = round_nearest ($y);

    if ($x >= 0 && $x < $width && $y >= 0 && $y < $height) {
      substr ($rows[$y], $x,length($n)) = $n;
    }

  }

  foreach my $row (@rows) {
    print $row,"\n";
  }
  exit 0;
}

{
  foreach my $i (0 .. 50) {
    my $theta = Math::PlanePath::ArchimedeanChords::_inverse($i);
    my $length = Math::PlanePath::ArchimedeanChords::_arc_length($theta);
    printf "%2d %8.3f %8.3f\n", $i, $theta, $length;
  }
  exit 0;
}
