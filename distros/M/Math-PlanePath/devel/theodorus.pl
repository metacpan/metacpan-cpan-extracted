#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012 Kevin Ryde

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

use 5.006;
use strict;
use warnings;
use POSIX 'floor', 'fmod';
use Math::Trig 'pi', 'atan';
use Math::BigFloat try => 'GMP';
use Math::Libm 'hypot';
use Math::PlanePath::TheodorusSpiral;
use Smart::Comments;


{
  # Euler summation

  # k<n           n                               n
  # sum f(k)  = integ f(x) dx - (f(n)-f(1))/2 + integ B1(frac(x))*f'(x) dx
  # k=1           1                               1
  #
  # B1(x) = x-1/2
  #
  # k<n           n
  # sum f(k)  = integ f(x) dx
  # k=1           1
  #
  #             - (f(n)-f(1))/2
  #
  #             + B2/2! (f'(n) - f'(1))
  #               ...
  #               (-1)^m*Bm     (m-1)       (m-1)
  #             + --------- * (f     (n) - f     (1))
  #                  m!
  #               ...
  # B0=1
  # B1=-1/2
  my $B2 = 1/6;
  my $B3 = 0;
  my $B4 = -1/30;

  # f(x) = arctan 1/sqrt(x)
  # f'(x) = 1/(1+x^2)
  # f'2(x) = (-1 * (2 * x)) / (((x ^ 2) + 1) ^ 2)
  #        = -2x / (x^2 + 1)^2

  foreach my $x (1 .. 40) {
    my $sum = fsum($x);
    my $ifx = ifx($x) - ifx(1) - (fx($x)-fx(1))/2;
    my $t1 = $B2/2 * (dfx($x) - dfx(1));
    my $if2 = $ifx + $t1;
    printf "%.4f %.4f[%.4f] %.4f[%.4f]\n",
      $sum, $ifx, $ifx-$sum, $if2, $if2-$sum;
  }

  sub ifx {
    my ($x) = @_;
    return sqrt($x) + $x*fx($x) - atan2($x,1);
  }
  sub fx {
    my ($x) = @_;
    return atan2(1, sqrt($x));
  }
  sub dfx {
    my ($x) = @_;
    return 1/($x*$x+1);
  }
  sub ddfx {
    my ($x) = @_;
    return -2*$x/(($x*$x+1)**2);
  }

  sub fsum {
    my ($x) = @_;
    my $ret = 0;
    foreach my $i (1 .. $x-1) {
      $ret += fx($x);
    }
    return $ret;
  }

  exit 0;
}

{
  {
    package Math::Symbolic::Custom::MySimplification;
    use base 'Math::Symbolic::Custom::Simplification';

    # use Math::Symbolic::Custom::Pattern;
    # my $formula = Math::Symbolic->parse_from_string("TREE_a * (TREE_b / TREE_c)");
    # my $pattern = Math::Symbolic::Custom::Pattern->new($formula);

    use Math::Symbolic::Custom::Transformation;
    my $trafo = Math::Symbolic::Custom::Transformation::Group->new
      (',',
       'TREE_a * (TREE_b / TREE_c)' => '(TREE_a * TREE_b) / TREE_c',
       'TREE_a * (TREE_b + TREE_c)' => 'TREE_a * TREE_b + TREE_a * TREE_c',
       '(TREE_b + TREE_c) * TREE_a' => 'TREE_b * TREE_a + TREE_c * TREE_a',

       # '(TREE_a / TREE_b) / TREE_c' => 'TREE_a / (TREE_b * TREE_c)',

       '(TREE_a / TREE_b) / (TREE_c / TREE_d)'
       => '(TREE_a * TREE_d) / (TREE_b * TREE_c)',

       '1 - TREE_a / TREE_b' => '(TREE_b - TREE_a) / TREE_b',

       'TREE_a / TREE_b + TREE_c' => '(TREE_a + TREE_b * TREE_c) / TREE_b',

       '(TREE_a / TREE_b) * TREE_c' => '(TREE_a * TREE_c) / TREE_b',

       'TREE_a - (TREE_b + TREE_c)' => 'TREE_a - TREE_b - TREE_c',
       '(TREE_a - TREE_b) - TREE_c' => 'TREE_a - TREE_b - TREE_c',

      );

    sub simplify {
      my $tree = shift;
      ### simplify(): "$tree"
      ### traf: ($trafo->apply_recursive($tree)//'').''
      return $trafo->apply_recursive($tree) || $tree;

      # if (my $m = $pattern->match($tree)) {
      #   $m = $m->{'trees'};
      #   ### trees: $m
      #   ### return: ($m->{'a'} * $m->{'b'}) / $m->{'c'}
      #   return ($m->{'a'} * $m->{'b'}) / $m->{'c'};
      # } else {
      #   ### no match
      #   return $tree;
      # }
    }
    __PACKAGE__->register();
  }

  require Math::Symbolic;
  require Math::Symbolic::Derivative;
  {
    my $t = Math::Symbolic->parse_from_string('1/(x^2+1)');
    $t = Math::Symbolic::Derivative::total_derivative($t, 'x');
    
    $t = $t->simplify;
    print "$t\n";
    exit 0;
  }

  {
    my $a = Math::Symbolic->parse_from_string(
                                              '(x+y)/(1-x*y)'
                                             );
    my $z = Math::Symbolic->parse_from_string(
                                              'z'
                                             );

    my $t = ($a + $z) / (1 - $a*$z);
    $t = $t->simplify;
    print $t;
    exit 0;
  }
}

{
  my $path = Math::PlanePath::TheodorusSpiral->new;
  my $prev_x = 0;
  my $prev_y = 0;
  #for (my $n = 10; $n < 100000000; $n = int($n * 1.2)) {
  foreach my $n (2000, 2010, 2020, 2010, 2000, 2010, 2000, 2010) {
    my ($x,$y) = $path->n_to_xy($n);
    my $rsq = $x*$x+$y*$y;

    my $dx = $x - $prev_x;
    my $dy = $y - $prev_y;
    my $dxy_dist = hypot($dx,$dy);

    printf "%d   %.2f,%.2f  %.2f  %.4f\n", $n, $x,$y, $rsq, $dxy_dist;

    ($prev_x, $prev_y) = ($x,$y);
  }
  exit 0;
}




sub integral {
  my ($x) = @_;
  print "log ", log(1+$x*$x), "  at x=$x\n";
  return $x * atan($x) - 0.5 * log (1 + $x*$x);
}
print "integral 0 = ", integral(0), "\n";
print "integral 1 = ", integral(1)/(2*pi()), "\n";
print "atan 1 = ", atan(1)/(2*pi()), "\n";

sub est {
  my ($n) = @_;
  my $k = $n-1;
  if ($k == 0) { return 0; }

  my $K = 2.1577829966;
  my $root = sqrt($k);
  my $a = 2*pi()*pi();
  my $radians;

  $radians = integral(1/$root); #  - integral(0);

  # $radians = ($k+1)*atan(1/$root) + $root - 1/($root*$k);
  return $radians / (2*pi());

  # $radians = 2*$root;
  # return $radians / (2*pi());
  # 
  # $radians = $root - atan($root) + $k*atan(1/$root);
  # return $radians / (2*pi());
  # 
  # return $k / $a;    # revolutions
  # return $k / pi();
  # 
  # return 2*$root / $a;
  # $radians = 2*sqrt($k+1) + $K + 1/(6*sqrt($k+1)); # plus O(n^(-3/2))
  # return 0.5 * $a * ($k * sqrt(1+$k*$k) + log($k + sqrt(1+$k*$k))) / $k;
  # return $root + ($k+1)*atan(1/$root);
}
print "est 1 = ", est(1), "\n";
print "est 2 = ", est(2), "\n";

{
  require Math::Polynomial;
  open OUT, '>', '/tmp/theodorus.data' or die;
  my @n;
  my @theta;
  my $total = 0;
  foreach my $n (2 .. 120) {
    my $inc = Math::Trig::atan(1/sqrt($n-1)) / (2*pi());  # revs
    $total += $inc;
    my $est = est($n);
    my $diff = $total - $est;
    # $diff = 1/$diff;
    if ($n > 50) {
      push @n, $n-51;
      push @theta, $diff;
      print OUT "$n $diff\n";
    }
    print "$n $inc $total $est   $diff\n";
  }
  print "\n";

  Math::BigFloat->accuracy(500);
  my $p = Math::Polynomial->new; # (Math::BigFloat->new(0));
  $p = $p->interpolate(\@n, \@theta);

  foreach my $i (0 .. $p->degree) {
    print "$i  ",$p->coeff($i),"\n";
  }
  # $p->string_config({ fold_sign => 1,
  #                     variable  => 'n' });
  # print "theta = $p\n";

  close OUT or die;
  system "xterm -e 'gnuplot  <devel/theodorus.gnuplot; read'";
  exit 0;
}

{
  my $next = 1;
  my $total = 0;
  my $n = 1;
  my $prev_n = 0;
  my $prev_diff = 0;
  my $total_diff_diff;
  my $count_diff_diff;
  for (;;) {
    my $inc = Math::Trig::atan2(1,sqrt($n++)) / (2*pi());
    $total += $inc;
    if ($total >= $next) {
      $next++;
      my $diff = $n - $prev_n;
      my $diff_diff = $diff - $prev_diff;
      $total_diff_diff += $diff_diff;
      $count_diff_diff++;
      print "$n +$diff +$diff_diff $total\n";
      if ($next >= 1000) {
        last;
      }
      $prev_n = $n;
      $prev_diff = $diff;
    }
  }
  my $avg = $total_diff_diff / $count_diff_diff;
  print "average $avg\n";
  print "\n";
  exit 0;
}

{
  my $c2 = 2.15778;
  my $t1 = 1.8600250;
  my $t2 = 0.43916457;
  my $z32 = 2.6123753486;
  my $tn1 = 2*$t1 - 2*$t2 - $z32;
  my $n = 1;
  my $x = 1;
  my $y = 0;

  while ($n < 10000) {
    my $r = sqrt($n); # before increment
    ($x, $y) = ($x - $y/$r, $y + $x/$r);
    $n++;

    $r = sqrt($n); # after increment

    my $theta = atan2($y,$x);
    if ($theta < 0) { $theta += 2*pi(); }
    my $root;
    $root = 2*sqrt($n) - $c2;
    # $root += .01/$r;

    # $root = -atan(sqrt($n)) + $n*atan(1/sqrt($n)) + sqrt($n);
    # $root = atan(1/sqrt($n)) - pi()/2 + $n*atan(1/sqrt($n)) + sqrt($n);
    $root = 2*sqrt($n)
      + 1/sqrt($n)
        - $c2
#           - 1/($n*sqrt($n))/3
#             + 1/($n*$n*sqrt($n))/5
#               - 1/($n*$n*sqrt($n))/7
#                 + 1/($n*$n*$n*sqrt($n))/9
                  ;
    #     $root = -pi()/4 + Arctan($r);
    #     foreach my $k (2 .. 1000000) {
    #       $root += atan(1/sqrt($k)) - atan(1/sqrt($k + $r*$r - 1));
    #       # $root += atan( ($r*$r - 1) / ( ($k + $r*$r)*sqrt($k) + ($k+1)*sqrt($k+$r*$r-1)));
    #     }

    # $root = -pi()/2 + Arctan($r) + $t1 *$r*$r/2 + ($tn1 - $t1)*$r**2/8;

    $root = fmod ($root, 2*pi());
    my $d = $root - $theta;
    $d = fmod ($d + pi(), 2*pi()) - pi();

    # printf  "%10.6f %10.6f %23.20f\n", $theta, $root, $d;
    printf  "%23.20f\n", $d;
  }
  exit 0;
}

{
  my $t1 = 0;
  foreach my $k (1 .. 100) {
    $t1 += 1 / (sqrt($k) * ($k+1));
  printf  "%10.6f\n", $t1;
  }
  exit 0;
}

sub Arctan {
  my ($r) = @_;
  return pi()/2 - atan(1/$r);
}

{
  Math::BigFloat->accuracy(200);
  my $bx = Math::BigFloat->new(1);
  my $by = Math::BigFloat->new(0);
  my $x = 1;
  my $y = 0;
  my $n = 1;

  my @n = ($n);
  my @x = ($x);
  my @y = ($y);
  my $count = 0;

  my $prev_n = 0;
      my $prev_d = 0;
  my @dd;

  while ($n++ < 10000000) {
    my $r = hypot($x,$y);
    my $py = $y;
    ($x, $y) = ($x - $y/$r, $y + $x/$r);

    if ($py < 0 && $y >= 0) {
      my $d = $n-$prev_n;
      my $dd = $d-$prev_d;
      push @dd, $dd;
      printf  "%5d +%4d +%3d %7.3f %10.6f %10.6f\n",
        $n,
          $d,
            $dd,
          # (sqrt($n)-1.07)/pi(),
          sqrt($n),
            $x, $y;
      $prev_n = $n;
      $prev_d = $d;
      if (++$count >= 10) {
        push @n, $n;
        push @x, $x;
        push @y, $y;
        $count = 0;
      }
    }
  }

  print "average dd ", List::Util::sum(@dd)/scalar(@dd),"\n";

#   require Data::Dumper;
#   print Data::Dumper->new([\@n],['n'])->Indent(1)->Dump;
#   print Data::Dumper->new([\@x],['x'])->Indent(1)->Dump;
#   print Data::Dumper->new([\@y],['y'])->Indent(1)->Dump;

  #   require Math::Polynomial;
  #   my $p = Math::Polynomial->new(0);
  #   $p = $p->interpolate([ 1 .. @nc ], \@nc);
  #   $p->string_config({ fold_sign => 1,
  #                       variable  => 'd' });
  #   print "N = $p\n";

  exit 0;
}

{
  Math::BigFloat->accuracy(200);
  my $bx = Math::BigFloat->new(1);
  my $by = Math::BigFloat->new(0);
  my $x = 1;
  my $y = 0;
  my $n = 1;

  while ($n++ < 10000) {
    my $r = hypot($x,$y);
    ($x, $y) = ($x - $y/$r, $y + $x/$r);

    my $br = sqrt($bx*$bx + $by*$by);
    ($bx, $by) = ($bx - $by/$br, $by + $bx/$br);

  }
  my $ex = "$bx" + 0;
  my $ey = "$by" + 0;
  printf  "%10.6f %10.6f %23.20f\n", $ex, $x, $ex - $x;
  exit 0;
}
