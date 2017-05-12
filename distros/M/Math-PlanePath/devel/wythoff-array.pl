#!/usr/bin/perl -w

# Copyright 2012, 2013 Kevin Ryde

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
use Math::PlanePath::WythoffArray;
use lib 't','xt';

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # tree A230871
  require Math::PlanePath::WythoffArray;
  my $wythoff = Math::PlanePath::WythoffArray->new (x_start => 1, y_start => 1);

  my @parent = (undef, 0);
  my @value = (0, 1);
  my @child_left = (1);
  my @child_right = (undef);
  my $value_seen = '';
  {
    my @pending = (1);
    foreach (0 .. 13) {
      my @new_pending;
      while (@pending) {
        my $i = shift @pending;
        my $value = $value[$i] // die "oops no value at $i";
        if ($value < 20000) { vec($value_seen,$value,1) = 1; }
        my $parent_i = $parent[$i];
        my $parent_value = $value[$parent_i];
        {
          my $left_value = $value + $parent_value;
          my $left_i = scalar(@value);
          $value[$left_i] = $left_value;
          $parent[$left_i] = $i;
          $child_left[$i] = $left_i;
          push @new_pending, $left_i;
        }
        {
          my $right_value =  3*$value - $parent_value;
          my $right_i = scalar(@value);
          $value[$right_i] = $right_value;
          $parent[$right_i] = $i;
          $child_right[$i] = $right_i;
          push @new_pending, $right_i;
        }
      }
      @pending = @new_pending;
    }
  }
  print "total nodes ",scalar(@value),"\n";

  my @rows;
  {
    # by rows
    my @pending = (0);
    while (@pending) {
      my @new_pending;
      my @row;
      while (@pending) {
        my $i = shift @pending;
        if (defined $child_left[$i]) {
          push @new_pending, $child_left[$i];
        }
        if (defined $child_right[$i]) {
          push @new_pending, $child_right[$i];
        }
        my $value = $value[$i];
        push @row, $value;
        if (@row < 20) {
          printf '%4d,', $value;
        }
      }
      print "\n";
      @pending = @new_pending;
      push @rows, \@row;
    }
  }

  # print columns
  {
    foreach my $c (0 .. 20) {
      print "col c=$c: ";
      foreach my $r (0 .. 20) {
        if (defined (my $value = $rows[$r]->[$c])) {
          print "$value,";
        }
      }
      print "\n";
    }        
  }

  my @wythoff_row;
  my @wythoff_step;
  my @triangle;
  {
    # wythoff row
    my $r = 0;
    my $c = 0;
    my %seen;
    my $print_c_limit = 300;
    for (;;) {
      my $v1 = $rows[$r]->[$c];
      if (! defined $v1) {
        $r++;
        if ($c < $print_c_limit) {
          print "next row\n";
        }
        next;
      }
      my $v2 = $rows[$r+1]->[$c];
      if (! defined $v2) {
        last;
      }

      if ($v1 <= $v2) {
        print "smaller v1: $v1 $v2\n";
      }

      $triangle[$v1][$v2] = 1;
      my ($x,$y,$step) = pair_to_wythoff_xy($v1,$v2);
      $x //= '[undef]';
      $y //= '[undef]';
      my $wv1 = $wythoff->xy_to_n($x,$y);
      my $wv2 = $wythoff->xy_to_n($x+1,$y);

      if ($c < $print_c_limit) {
        print "$c  $v1,$v2   $x, $y   $step is $wv1, $wv2\n";
      }
      if ($c < 40) {
        push @wythoff_row, $y;
        push @wythoff_step, $step;
      }
      if (defined $seen{$y}) {
        print "seen $y  at $seen{$y}\n";
      }
      $seen{$y} = $c;

      $c++;
    }
    print "stop at column $c\n";

    print "\n";
  }

  {
    # print triangle
    foreach my $v1 (reverse 0 .. 80) {
      foreach my $v2 (0 .. 80) {
        print $triangle[$v1][$v2] ? '*' : ' ';
      }
      print "\n";
    }
  }

  @wythoff_row = sort {$a<=>$b} @wythoff_row;
  foreach (1, 2) {
    print join(',',@wythoff_row),"\n";
    {
      require Math::NumSeq::Fibbinary;
      my $fib = Math::NumSeq::Fibbinary->new;
      print join(',',map{sprintf '%b',$fib->ith($_)} @wythoff_row),"\n";
    }
    foreach (@wythoff_row) { $_-- }
    print "\n";
  }

  print "step: ",join(',',@wythoff_step),"\n";

  require MyOEIS;
  MyOEIS::compare_values
      (anum => 'A230872',
       name => 'tree all values occurring',
       max_count => 700,
       func => sub {
         my ($count) = @_;
         my @got = (0);
         for (my $i = 0; @got < $count; $i++) {
           if (vec($value_seen,$i,1)) {
             push @got, $i;
           }
         }
         return \@got;
       });
  MyOEIS::compare_values
      (anum => 'A230871',
       name => 'tree table',
       func => sub {
         my ($count) = @_;
         my @got;
         my $r = 0;
         my $c = 0;
         while (@got < $count) {
           my $row = $rows[$r] // last;
           if ($c > $#$row) {
             $r++;
             $c = 0;
             next;
           }
           push @got, $row->[$c];
           $c++;
         }
         return \@got;
       });

  exit 0;

  sub pair_to_wythoff_xy {
    my ($v1,$v2) = @_;
    foreach my $step (0 .. 500) {
      # use Smart::Comments;
      ### at: "seek $v1, $v2  step $_"
      if (my ($x,$y) = $wythoff->n_to_xy($v1)) {
        my $wv2 = $wythoff->xy_to_n($x+1,$y);
        if (defined $wv2 && $wv2 == $v2) {
          ### found: "pair $v1 $v2 at x=$x y=$x"
          return ($x,$y,$step);
        }
      }
      ($v1,$v2) = ($v2,$v1+$v2);
    }
  }
}
{
  # left-justified shift amount
  require Math::NumSeq::Fibbinary;
  my $fib = Math::NumSeq::Fibbinary->new;
  my $path = Math::PlanePath::WythoffArray->new;
  foreach my $y (0 .. 50) {
    my $a = $path->xy_to_n(0,$y);
    my $b = $path->xy_to_n(1,$y);
    my $count = 0;
    while ($a < $b) {
      ($a,$b) = ($b-$a,$a);
      $count++;
    }
    my $y_fib = sprintf '%b',$fib->ith($y);
    print "$y  $y_fib  $count\n";
    # $count = ($count+1)/2;
    # print "$count,";
  }
  exit 0;
}

{
  # Y*phi
  use constant PHI => (1 + sqrt(5)) / 2;
  my $path = Math::PlanePath::WythoffArray->new (y_start => 0);
  foreach my $y ($path->y_minimum .. 20) {
    my $n = $path->xy_to_n(0,$y);
    my $prod = int(PHI*PHI*$y + PHI);
    print "$y  $n $prod\n";
  }
  exit 0;
}
{
  # dual
  require Math::NumSeq::Fibbinary;
  my $seq = Math::NumSeq::Fibbinary->new;
  foreach my $value
    (
1 .. 300,
     1,
     #                                                    # 1,10
     # 4, 6, 10, 16, 26, 42, 68, 110, 178, 288, 466       # 101,1001
     # 7, 11, 18, 29, 47, 76, 123, 199, 322, 521, 843     # 1010,10100
     # 9, 14, 23, 37, 60, 97, 157, 254, 411, 665, 1076,   # 10001,100001
     # 12, 19, 31, 50, 81, 131, 212, 343, 555, 898, 1453  # 10101,101001

    ) {
    my $z = $seq->ith($value);
    printf "%3d %6b\n", $value, $z;
  }
  exit 0;
}

{
  # Fibbinary with even trailing 0s
  require Math::NumSeq::Fibbinary;
  require Math::NumSeq::DigitCountLow;
  my $seq = Math::NumSeq::Fibbinary->new;
  my $cnt = Math::NumSeq::DigitCountLow->new (radix => 2, digit => 0);
  my $e = 0;
  foreach (1 .. 40) {
    my ($i,  $value) = $seq->next;
    my $c = $cnt->ith($value);
    my $str = ($c % 2 ? 'odd' : 'even');
    my $ez = $seq->ith($e);
    if ($c % 2 == 0) {
      printf "%2d %6b %s [%d]   %5b\n", $i, $value, $str, $c, $ez;
    } else {
      printf "%2d %6b %s [%d]\n", $i, $value, $str, $c;
    }
    if ($c % 2 == 0) {
      $e++;
    }
  }
  exit 0;
}

{
  require Math::BaseCnv;
  require Math::PlanePath::PowerArray;
  my $path;
  my $radix = 3;
  my $width = 9;
  $path = Math::PlanePath::PowerArray->new (radix => $radix);
  foreach my $y (reverse 0 .. 6) {
    foreach my $x (0 .. 5) {
      my $n = $path->xy_to_n($x,$y);
      my $nb = sprintf '%*s', $width, Math::BaseCnv::cnv($n,10,$radix);
      print $nb;
    }
    print "\n";
  }
  exit 0;
}

{
  # max Dir4

  require Math::BaseCnv;

  print 4-atan2(2,1)/atan2(1,1)/2,"\n";

  require Math::NumSeq::PlanePathDelta;
  my $realpart = 3;
  my $radix = $realpart*$realpart + 1;
  my $planepath = "WythoffArray";
   $planepath = "GcdRationals,pairs_order=rows_reverse";
  my $seq = Math::NumSeq::PlanePathDelta->new (planepath => $planepath,
                                               delta_type => 'Dir4');
  my $dx_seq = Math::NumSeq::PlanePathDelta->new (planepath => $planepath,
                                                  delta_type => 'dX');
  my $dy_seq = Math::NumSeq::PlanePathDelta->new (planepath => $planepath,
                                                  delta_type => 'dY');
  my $max = -99;
  for (1 .. 1000000) {
    my ($i, $value) = $seq->next;
    $value = -$value;
    if ($value > $max) {
      my $dx = $dx_seq->ith($i);
      my $dy = $dy_seq->ith($i);
      my $ri = Math::BaseCnv::cnv($i,10,$radix);
      my $rdx = Math::BaseCnv::cnv($dx,10,$radix);
      my $rdy = Math::BaseCnv::cnv($dy,10,$radix);
      my $f = $dy && $dx/$dy;
      printf "%d %s %.5f  %s %s   %.3f\n", $i, $ri, $value, $rdx,$rdy, $f;
      $max = $value;
    }
  }

  exit 0;
}
