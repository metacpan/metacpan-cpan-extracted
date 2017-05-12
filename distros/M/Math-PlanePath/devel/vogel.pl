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

use 5.010;
use strict;
use warnings;
use POSIX 'fmod';
use List::Util 'min', 'max';
use Math::Libm 'M_PI', 'hypot';
use Math::Trig 'pi';
use POSIX;

use Smart::Comments;

use constant PHI => (1 + sqrt(5)) / 2;


{
  require Math::PlanePath::VogelFloret;

  my $width = 79;
  my $height = 21;

  my $x_factor = 1.4;
  my $y_factor = 2;
  my $n_hi = 99;

  require Math::NumSeq::OEIS;
  my $seq = Math::NumSeq::OEIS->new(anum => 'A000201');
  print_class('Math::PlanePath::VogelFloret');

  require Math::NumSeq::FibonacciWord;
  $seq = Math::NumSeq::FibonacciWord->new;
   $y_factor = 1.2;
  $n_hi = 73;
  print_class('Math::PlanePath::VogelFloret');

  sub print_class {
    my ($name) = @_;

    # secret leading "*Foo" means print if available
    my $if_available = ($name =~ s/^\*//);

    my $class = $name;
    unless ($class =~ /::/) {
      $class = "Math::PlanePath::$class";
    }
    ($class, my @parameters) = split /\s*,\s*/, $class;

    $class =~ /^[a-z_][:a-z_0-9]*$/i or die "Bad class name: $class";
    if (! eval "require $class") {
      if ($if_available) {
        next;
      } else {
        die $@;
      }
    }

    @parameters = map { /(.*?)=(.*)/ or die "Missing value for parameter \"$_\"";
                        $1,$2 } @parameters;

    my %rows;
    my $x_min = 0;
    my $x_max = 0;
    my $y_min = 0;
    my $y_max = 0;
    my $cellwidth = 1;

    my $path = $class->new (width  => POSIX::ceil($width / 4),
                            height => POSIX::ceil($height / 2),
                            @parameters);
    my $x_limit_lo;
    my $x_limit_hi;
    if ($path->x_negative) {
      my $w_cells = int ($width / $cellwidth);
      my $half = int(($w_cells - 1) / 2);
      $x_limit_lo = -$half;
      $x_limit_hi = +$half;
    } else {
      my $w_cells = int ($width / $cellwidth);
      $x_limit_lo = 0;
      $x_limit_hi = $w_cells - 1;
    }

    my $y_limit_lo = 0;
    my $y_limit_hi = $height-1;
    if ($path->y_negative) {
      my $half = int(($height-1)/2);
      $y_limit_lo = -$half;
      $y_limit_hi = +$half;
    }

    my $is_01 = $seq->characteristic('smaller');
    ### seq: ref $seq
    ### $is_01

    $rows{0}{0} = '.';

    my $n_start = $path->n_start;
    my $n = $n_start;
    for (;;) {
      my ($x, $y) = $path->n_to_xy ($n);

      # stretch these out for better resolution
      if ($class =~ /Sacks/) { $x *= 1.5; $y *= 2; }
      if ($class =~ /Archimedean/) { $x *= 2; $y *= 3; }
      if ($class =~ /Theodorus|MultipleRings/) { $x *= 2; $y *= 2; }
      if ($class =~ /Vogel/) { $x *= $x_factor; $y *= $y_factor; }

      # nearest integers
      $x = POSIX::floor ($x + 0.5);
      $y = POSIX::floor ($y + 0.5);

      my $cell = $rows{$x}{$y};
      if (defined $cell) { $cell .= ','; }
      if ($is_01) {
        $cell .= $seq->ith($n);
      } else {
        $cell .= $n;
      }
      my $new_cellwidth = max ($cellwidth, length($cell) + 1);

      my $new_x_limit_lo;
      my $new_x_limit_hi;
      if ($path->x_negative) {
        my $w_cells = int ($width / $new_cellwidth);
        my $half = int(($w_cells - 1) / 2);
        $new_x_limit_lo = -$half;
        $new_x_limit_hi = +$half;
      } else {
        my $w_cells = int ($width / $new_cellwidth);
        $new_x_limit_lo = 0;
        $new_x_limit_hi = $w_cells - 1;
      }

      my $new_x_min = min($x_min, $x);
      my $new_x_max = max($x_max, $x);
      my $new_y_min = min($y_min, $y);
      my $new_y_max = max($y_max, $y);
      if ($new_x_min < $new_x_limit_lo
          || $new_x_max > $new_x_limit_hi
          || $new_y_min < $y_limit_lo
          || $new_y_max > $y_limit_hi) {
        last;
      }

      $rows{$x}{$y} = $cell;
      $cellwidth = $new_cellwidth;
      $x_limit_lo = $new_x_limit_lo;
      $x_limit_hi = $new_x_limit_hi;
      $x_min = $new_x_min;
      $x_max = $new_x_max;
      $y_min = $new_y_min;
      $y_max = $new_y_max;

      if ($is_01) {
        $n++;
      } else {
        (my $i, $n) = $seq->next;
      }
      last if $n > $n_hi;
    }
    $n--; # the last N actually plotted

    print "$name   N=$n_start to N=$n\n\n";
    foreach my $y (reverse $y_min .. $y_max) {
      foreach my $x ($x_limit_lo .. $x_limit_hi) {
        my $cell = $rows{$x}{$y};
        if (! defined $cell) { $cell = ''; }
        printf ('%*s', $cellwidth, $cell);
      }
      print "\n";
    }
  }
    exit 0;
}


sub cont {
  my $ret = pop;
  while (@_) {
    $ret = (pop @_) + 1/$ret;
  }
  return $ret;
}
### phi: cont(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1)

{
  # use constant ROTATION => M_PI-3;
  # use constant ROTATION => PHI;
  #use constant ROTATION => sqrt(37);
  use constant ROTATION => cont(1 .. 20);

  my $margin = 0.999;
  # use constant K => 6;
  # use constant ROTATION => (K + sqrt(4+K*K)) / 2;
  print "ROTATION ",ROTATION,"\n";
  my @n;
  my @r;
  my @x;
  my @y;
  my $prev_d = 5;
  my $min_d = 5;
  my $min_n1 = 0;
  my $min_n2 = 0;
  my $min_x2 = 0;
  my $min_y2 = 0;
  for (my $n = 1; $n < 100_000_000; $n++) {
    my $r = sqrt($n);
    my $theta = $n * ROTATION() * 2*pi();  # radians
    my $x = $r * cos($theta);
    my $y = $r * sin($theta);

    foreach my $i (0 .. $#n) {
      my $d = hypot ($x-$x[$i], $y-$y[$i]);
      if ($d < $min_d) {
        $min_d = $d;
        $min_n1 = $n[$i];
        $min_n2 = $n;
        $min_x2 = $x;
        $min_y2 = $y;
        if ($min_d / $prev_d < $margin) {
          $prev_d = $min_d;
          print "$min_n1 $min_n2   $min_d ", 1/$min_d, "\n";
          print "  x=$min_x2 y=$min_y2\n";
        }
      }
    }

    push @n, $n;
    push @r, $r;
    push @x, $x;
    push @y, $y;

    if ((my $r_lo = sqrt($n) - 1.2 * $min_d) > 0) {
      while (@n > 1) {
        if ($r[0] >= $r_lo) {
          last;
        }
        shift @r;
        shift @n;
        shift @x;
        shift @y;
      }
    }
  }
  print "$min_n1 $min_n2   $min_d ", 1/$min_d, "\n";
  print "  x=$min_x2 y=$min_y2\n";
  exit 0;
}


{
  my $x = 3;
  foreach (1 .. 100) {
    $x = 1 / (1 + $x);
  }
}

# {
#   # 609 631   0.624053229799566 1.60242740883046
#   # 2 7   1.47062247517163 0.679984167849259
#
#   use constant ROTATION => M_PI-3;
#   my @x;
#   my @y;
#   foreach my $n (1 .. 20000) {
#     my $r = sqrt($n);
#     # my $theta = 2 * $n;  # radians
#     my $theta = $n * ROTATION() * 2*pi();  # radians
#     push @x, $r * cos($theta);
#     push @y, $r * sin($theta);
#   }
#   # ### @x
#   my $min_d = 999;
#   my $min_i = 0;
#   my $min_j = 0;
#   my $min_xi = 0;
#   my $min_yi = 0;
#   foreach my $i (0 .. $#x-1) {
#     my $xi = $x[$i];
#     my $yi = $y[$i];
#     foreach my $j ($i+1 .. $#x) {
#       my $d = hypot ($xi-$x[$j], $yi-$y[$j]);
#       if ($d < $min_d) {
#         $min_d = $d;
#         $min_i = $i;
#         $min_j = $j;
#         $min_xi = $xi;
#         $min_yi = $yi;
#       }
#     }
#   }
#   print "$min_i $min_j   $min_d ", 1/$min_d, "\n";
#   print "  x=$min_xi y=$min_yi\n";
#   exit 0;
# }

# {
#   require Math::PlanePath::VogelFloret;
#   use constant FACTOR => do {
#     my @c = map {
#       my $n = $_;
#       my $r = sqrt($n);
#       my $revs = $n / (PHI * PHI);
#       my $theta = $revs * 2*M_PI();
#       ### $n
#       ### $r
#       ### $revs
#       ### $theta
#       ($r*cos($theta), $r*sin($theta))
#     } 1, 4;
#     ### @c
#     ### hypot: hypot ($c[0]-$c[2], $c[1]-$c[3])
#     1 / hypot ($c[0]-$c[2], $c[1]-$c[3])
#   };
#   ### FACTOR: FACTOR()
#
#   print "FACTOR ", FACTOR(), "\n";
#   # print "FACTOR ", Math::PlanePath::VogelFloret::FACTOR(), "\n";
#   exit 0;
# }

{
  foreach my $i (0 .. 20) {
    my $f = PHI**$i/sqrt(5);
    my $rem = fmod($f,PHI);
    printf "%11.5f  %6.5f\n", $f, $rem;
  }
  exit 0;
}

{
  foreach my $n (18239,19459,25271,28465,31282,35552,43249,74592,88622,
                 101898,107155,116682) {
    my $theta = $n / (PHI * PHI);  # 1==full circle
    printf "%6d  %.2f\n", $n, $theta;
  }
  exit 0;
}

foreach my $i (2 .. 5000) {
  my $rem = fmod ($i, PHI*PHI);
  if ($rem > 0.5) {
    $rem = $rem - 1;
  }
  if (abs($rem) < 0.02) {
    printf "%4d  %6.3f  %s\n", $i,$rem,factorize($i);
  }
}


sub factorize {
  my ($n) = @_;
  my @factors;
  foreach my $f (2 .. int(sqrt($n)+1)) {
    if (($n % $f) == 0) {
      push @factors, $f;
      $n /= $f;
      while (($n % $f) == 0) {
        $n /= $f;
      }
    }
  }
  return join ('*',@factors);
}
exit 0;

#     pi    => { rotation_factor => M_PI() - 3,
#                rfactor    => 2,
#                # ever closer ?
#                # 298252 298365   0.146295611059244 6.83547505464836
#                #   x=-142.771526420416 y=527.239311170539
#              },
# # BEGIN {
# #   foreach my $info (rotation_types()) {
# #     my $rot = $info->{'rotation_factor'};
# #     my $n1 = $info->{'closest_Ns'}->[0];
# #     my $r1 = sqrt($n1);
# #     my $t1 = $n1 * $rot * 2*M_PI();
# #     my $x1 = cos ($t1);
# #     my $y1 = sin ($t1);
# #
# #     my $r2 = sqrt($n2);
# #     my $t2 = $n2 * $rot * 2*M_PI();
# #     my $x2 = cos ($t2);
# #     my $y2 = sin ($t2);
# #
# #     $info->{'rfactor'} = 1 / hypot ($x1-$x2, $y1-$y2);
# #   }
# # }

