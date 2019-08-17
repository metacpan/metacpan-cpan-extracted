#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013, 2014, 2015, 2016, 2019 Kevin Ryde

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
use List::Util 'min', 'max';
use Math::Trig 'pi';
use Math::PlanePath::Base::Digits 'digit_split_lowtohigh';
use lib 'xt';
use MyOEIS;

# uncomment this to run the ### lines
# use Smart::Comments;

=head2 Right Boundary Segment N

The segment numbers which are the right boundary, being the X axis and
notches there, are

    N such that N+2 in base-4 has
      least significant digit any 0,1,2,3
      above that only digits 0,2

    = 0,1, 2,3,4,5, 14,15,16,17, 18,19,20,21, 62,63,64,65, ...

=head2 Left Boundary Segment N

The segment numbers which are the left boundary, being the stair-step
diagonal, are

    N such that N+1 in base-4 has
      least significant digit any 0,1,2,3
      above that only digits 0,2

    = 0,1,2, 7,8,9,10, 31,32,33,34, 39,40,41,42, 127,128,129,130, ...

=cut

{
  # Sum, would be an i_to_n_offset
  require Math::NumSeq::PlanePathCoord;
  my $seq = Math::NumSeq::PlanePathCoord->new (planepath => 'AlternatePaper',
                                               coordinate_type => 'Sum',
                                               i_start => 0,
                                               n_start => 1);
  foreach (1..6) {
    my ($i,$value) = $seq->next;
    print "$i $value\n";
  }
  exit 0;
}

{
  # resistance
  #
  #     2---3
  #     |   |
  # 0---1   4
  #
  # vertices 5
  # 4
  # 4.000000000000000000000000000
  # level=2
  # vertices 14
  # 28/5
  # 5.600000000000000000000000000
  # level=3
  # vertices 44
  # 32024446704/4479140261
  # 7.149686064273931429806591627
  # level=4
  # vertices 152
  # 6628233241945519690439003608662864691664896192990656/773186632952527929515144502921021371068970539201685
  # 8.572617476112626473076554400
  #
  # shortcut on X axis
  #     2---3
  #     |   |     1 + 1/(1+1/3) = 1+3/4
  # 0---1---4  
  # 1
  # 1.000000000000000000000000000
  # level=1
  # vertices 5
  # 7/4
  # 1.750000000000000000000000000
  # level=2
  # vertices 14
  # 73/26
  # 2.807692307692307692307692308
  # level=3
  # vertices 44
  # 2384213425/588046352
  # 4.054465123184711126309308352
  # level=4
  # vertices 152
  # 2071307229966623393952039649887056624274965452048209/386986144302228882053693423947791758105522022410048
  # 5.352406695855682889687320523
  #
  sub to_bigrat {
    my ($n) = @_;
    return $n;
    require Math::BigRat;
    return Math::BigRat->new($n);
  }
  my @dir4_to_dx = (1,0,-1,0);
  my @dir4_to_dy = (0,1,0,-1);

  require Math::PlanePath::AlternatePaper;
  my $path = Math::PlanePath::AlternatePaper->new;
  foreach my $level (0 .. 9) {
    print "level=$level\n";
    my %xy_to_index;
    my %xy_to_value;
    my $index = 0;
    my @rows;
    my $n_lo = 0;
    my $n_hi = 2*4**$level;
    foreach my $n ($n_lo .. $n_hi) {
      my ($x,$y) = $path->n_to_xy($n);
      my $xy = "$x,$y";
      if (! exists $xy_to_index{$xy}) {
        ### vertex: "$x,$y index=$index"
        $xy_to_index{$xy} = $index++;
        $xy_to_value{$xy} = ($n == $n_lo ? to_bigrat(-1)
                             : $n == $n_hi ? to_bigrat(1)
                             : to_bigrat(0));
      }
    }
    foreach my $xy (keys %xy_to_index) {
      my @row = (to_bigrat(0)) x $index;
      $row[$index] = $xy_to_value{$xy};
      my $i = $xy_to_index{$xy};
      if ($i == 0) {
        $row[$i] = 1;
        $row[$index] = 0;
      } else {
        my ($x,$y) = split /,/, $xy;
        ### point: "$x,$y"
        foreach my $dir4 (0 .. $#dir4_to_dx) {
          my $dx = $dir4_to_dx[$dir4];
          my $dy = $dir4_to_dy[$dir4];
          my $x2 = $x+$dx;
          my $y2 = $y+$dy;
          my $n = $path->xyxy_to_n ($x,$y, $x2,$y2);
          if (defined $n && $n < $n_hi) {
            my $i2 = $xy_to_index{"$x2,$y2"};
            ### edge: "$x,$y to $x2,$y2  $i to $i2"
            $row[$i]++;
            $row[$i2]--;
          }
        }
      }
      push @rows, \@row;
    }
    print "vertices $index\n";
    ### @rows
    require Math::Matrix;
    my $m = Math::Matrix->new(@rows);
    # print $m;
    if (0) {
      my $s = $m->solve;
      # print $s;
      foreach my $i (0 .. $index-1) {
        print " ",$s->[$i][0],",";
      }
      print "\n";
      my $V = $s->[0][0];
      print int($V),"+",$V-int($V),"\n";
    }
    {
      open my $fh, '>', '/tmp/x.gp' or die;
      mm_print_pari($m,$fh);
      print $fh "; s=matsolve(m,v); print(s[$index,1]);s[$index,1]+0.0\n";
      close $fh;
      require IPC::Run;
      IPC::Run::run(['gp','--quiet'],'<','/tmp/x.gp');
    }
  }
  exit 0;

  sub mm_print_pari {
    my ($m, $fh) = @_;
    my ($rows, $cols) = $m->size;
    print $fh "m=[\\\n";
    my $semi = '';
    foreach my $r (0 .. $rows-1) {
      print $fh $semi;
      $semi = ";\\\n";
      my $comma = '';
      foreach my $c (0 .. $cols-2) {
        print $fh $comma, $m->[$r][$c];
        $comma = ',';
      }
    }
    print $fh "];\\\nv=[";
    $semi = '';
    foreach my $r (0 .. $rows-1) {
      print $fh $semi, $m->[$r][$cols-1];
      $semi = ';';
    }
    print $fh "]";
  }
}

{
  # left boundary
  require Math::PlanePath::AlternatePaper;
  my $path = Math::PlanePath::AlternatePaper->new;
  my @values;
  for (my $n = $path->n_start; @values < 30; $n++) {
    if ($path->_UNDOCUMENTED__n_segment_is_right_boundary($n)) {
      push @values, $n;
    }
  }
  print join(',',@values),"\n";
  Math::OEIS::Grep->search(array=>\@values);
  exit;
}


{
  # base 4 reversal

  # 1000     0
  #  111     1
  #  110    10
  #  101    11
  #  100   100
  #   11   101
  #   10   110
  #    1   111
  #    0  1000

  require Math::BaseCnv;
  require Math::PlanePath::AlternatePaper;
  my $path = Math::PlanePath::AlternatePaper->new;
  foreach my $i (0 .. 32) {
    my $nx = $path->xy_to_n($i,0);
    my $nxr = $path->xy_to_n(32-$i,0);
    printf "%6s  ", Math::BaseCnv::cnv($nx, 10,4);
    printf "%6s  ", Math::BaseCnv::cnv($nxr, 10,4);

    my $c = 3*$nx + 3*$nxr;
    printf "%6s  ", Math::BaseCnv::cnv($c, 10,4);
    print "\n";
  }
  print "\n";
  exit 0;
}

{
  # N pairs in X=2^k columns

  #   8 |                                                      128
  #     |                                                       |
  #   7 |                                                42---43/127
  #     |                                                |      |
  #   6 |                                         40---41/45--44/124
  #     |                                         |      |      |
  #   5 |                                  34---35/39--38/46--47/123
  #     |                                  |      |      |      |
  #   4 |                           32---33/53--36/52--37/49--48/112
  #     |                           |      |      |      |      |
  #   3 |                    10---11/31--30/54--51/55--50/58--59/111
  #     |                    |      |      |      |      |      |
  #   2 |              8----9/13--12/28--29/25--24/56--57/61--60/108
  #     |              |     |      |      |      |      |      |
  #   1 |        2----3/7---6/14--15/27--26/18--19/23---22/62--63/107
  #     |        |     |     |      |      |      |      |      |
  # Y=0 |  0-----1     4-----5     16-----17     20-----21     64---..
  #
  #     *
  #   / | \
  # *---*---*
  #                                      2000-0
  #                                      2000-1
  #                                      2000-10
  #                                      2000-11
  #                                      2000-100
  #                             1000-1001
  #
  # 0  1  10  11  100 101 110 111 1000  1001 1010 1011 1100 1101 1110 1111 10000
  #                               X=8
  #                               N=64
  # left vert = 1000 - horiz
  # right vert = 2000 - horiz reverse
  #
  require Math::PlanePath::AlternatePaper;
  require Math::BaseCnv;
  my $path = Math::PlanePath::AlternatePaper->new;

  print "X  ";
  foreach my $x (0 .. 16) {
    my $nx = $path->xy_to_n($x,0);
    print " ",Math::BaseCnv::cnv($nx, 10,4);
  }
  print "\n";


  foreach my $k (0 .. 3) {
    my $x = 2**$k;
    my $x4 = Math::BaseCnv::cnv($x,10,4);

    print "k=$k  x=$x [$x4]\n";
    foreach my $y (reverse 0 .. $x) {
      printf " y=%2d", $y;
      my $nx = $path->xy_to_n($y,0);
      my $nxr = $path->xy_to_n($x-$y,0);
      my $nd = $path->xy_to_n($y,$y);

      my @n_list = $path->xy_to_n_list($x,$y);
      foreach my $n (@n_list) {
        printf " %3d[%6s]", $n, Math::BaseCnv::cnv($n,10,4);
      }
      my ($na,$nb) = @n_list;
      print "   ";
      print "  ",Math::BaseCnv::cnv(4**$k - $nx, 10,4);
      print "  ",Math::BaseCnv::cnv(2*4**$k - $nxr, 10,4);
      print "\n";
    }
  }
  exit 0;
}

{
  # revisit
  require Math::NumSeq::PlanePathCoord;
  my $seq = Math::NumSeq::PlanePathCoord->new (planepath => 'AlternatePaper',
                                               coordinate_type => 'Revisit');
  foreach my $n (0 .. 4*4*4*64) {
    my $want = $seq->ith($n);
    my $got = n_to_revisit($n);
    my $diff = ($want == $got ? '' : ' ***');
    print "$n  $want   $got$diff\n";
    last if $diff;
  }

  sub n_to_revisit {
    my ($n) = @_;
    ### n_to_revisit(): $n
    my @digits = digit_split_lowtohigh($n,4);
    ### digits: join(',', reverse @digits)

    my $rev = 0;
    foreach my $digit (reverse @digits) {  # high to low
      if ($rev) {
        $rev ^= ($digit == 0 || $digit == 2);
      } else {
        $rev ^= ($digit == 1 || $digit == 3);
      }
    }
    ### $rev

    my $h = 1;
    my $v = 1;
    my $d = 1;
    my $nonzero = 0;
    while (defined (my $digit = shift @digits)) { # low to high
      if ($rev) {
        $rev ^= ($digit == 0 || $digit == 2);
      } else {
        $rev ^= ($digit == 1 || $digit == 3);
      }
      ### at: "h=$h v=$v d=$d rev=$rev   digit=$digit nonzero=$nonzero"
      if ($rev) {
        if ($digit == 0) {
          $h = 0;
          $d = 0;
        } elsif ($digit == 1) {
          if ($v) {
            ### return nonzero ...
            return $nonzero ? 1 : 0;
          }
        } elsif ($digit == 2) {
          if ($d) {
            ### return nonzero ...
            return $nonzero ? 1 : 0;
          }
          $h = 0;
        } else { # $digit == 3
          $h = 0;
        }
      } else {
        # forward
        if ($digit == 0) {
          $v = 0;
        } elsif ($digit == 1) {
          if ($h) { return $nonzero ? 1 : 0; }
          $h = $v;
          $d = 0;
        } elsif ($digit == 2) {
          $h = 0;
        } else { # $digit == 3
          if ($v || $d) { return $nonzero ? 1 : 0; }
          $v = $h;
          $h = 0;
        }
      }
      $nonzero ||= $digit;
    }
    ### at: "final h=$h v=$v d=$d rev=$rev"

    return 0;
  }
  sub Xn_to_revisit {
    my ($n) = @_;
    ### n_to_revisit(): $n
    my $h = 0;
    my $v = 0;
    my $d = 0;
    my @digits = reverse digit_split_lowtohigh($n,4);
    ### digits: join(',',@digits)

    while (@digits && $digits[-1] == 0) {
      pop @digits;  # strip low zero digits
    }
    my $low = pop @digits || 0;
    my $rev = 0;
    while (defined (my $digit = shift @digits)) {
      ### at: "rev=$rev h=$h v=$v d=$d  digit=$digit more=".scalar(@digits)
      if ($rev) {
        if ($digit == 0) {
          $v = 0;
          $d = 0;
          $rev ^= 1;  # forward again
        } elsif ($digit == 1) {
          $v = ($low ? 1 : 0);
        } elsif ($digit == 2) {
          $h = 0;
          $d = ($low ? 1 : 0);
          $rev ^= 1;
        } else { # $digit == 3
          $h = ($low ? 1 : 0);
        }
      } else {
        # forward
        if ($digit == 0) {
          $v = 0;
        } elsif ($digit == 1) {
          $v = ($low ? 1 : 0);
          $d = 0;
          $rev ^= 1;
        } elsif ($digit == 2) {
          $h = 0;
        } else { # $digit == 3
          $h = ($low ? 1 : 0);
          $d = 1;
          $rev ^= 1;
        }
      }
    }
    ### at: "final rev=$rev h=$h v=$v d=$d"

    # return ($h || $v);
    # return ($h || $v || $d);
    if ($rev) {
      if ($low == 0) {
        return $h || $v;
      } elsif ($low == 1) {
        return $h;
      } elsif ($low == 2) {
        return $d;
      } else { # $digit == 3
        return $v;
      }
    } else {
      if ($low == 0) {
        return $h || $d;
      } elsif ($low == 1) {
        return $h;
      } elsif ($low == 2) {
        return $d;
      } else { # $digit == 3
        return $v;
      }
    }
  }
  exit 0;
}

{
  # total turn
  require Math::PlanePath::AlternatePaper;
  require Math::BaseCnv;
  my $path = Math::PlanePath::AlternatePaper->new;
  my $total = 0;
  my $bits_total = 0;
  my @values;
  for (my $n = 1; $n <= 32; $n++) {
    my $n2 = Math::BaseCnv::cnv($n,10,2);
    my $n4 = Math::BaseCnv::cnv($n,10,4);
    printf "%10s %10s  %2d %2d\n", $n2, $n4, $total, $bits_total;

    # print "$total,";
    push @values, $total;

    $bits_total = total_turn_by_bits($n);

    my $turn = path_n_turn ($path, $n);
    if ($turn == 1) { # left
      $total++;
    } elsif ($turn == 0) { # right
      $total--;
    } else {
      die;
    }
  }

  print join(',',@values),"\n";
  Math::OEIS::Grep->search(array=>\@values);

  use Math::PlanePath;
  use Math::PlanePath::GrayCode;
  sub total_turn_by_bits {
    my ($n) = @_;
    my $bits = [ digit_split_lowtohigh($n,2) ];
    my $rev = 0;
    my $total = 0;
    for (my $pos = $#$bits; $pos >= 0; $pos--) { # high bit to low bit
      my $bit = $bits->[$pos];
      if ($rev) {
        if ($bit) {
        } else {
          if ($pos & 1) {
            $total--;
          } else {
            $total++;
          }
          $rev = 0;
        }
      } else {
        if ($bit) {
          if ($pos & 1) {
            $total--;
          } else {
            $total++;
          }
          $rev = 1;
        } else {
        }
      }
    }
    return $total;
  }

  exit 0;
}
{
  require Math::PlanePath::AlternatePaper;
  require Math::PlanePath::AlternatePaperMidpoint;
  my $paper = Math::PlanePath::AlternatePaper->new (arms => 8);
  my $midpoint = Math::PlanePath::AlternatePaperMidpoint->new (arms => 8);
  foreach my $n (0 .. 7) {
    my ($x1,$y1) = $paper->n_to_xy($n);
    my ($x2,$y2) = $paper->n_to_xy($n+8);
    my ($mx,$my) = $midpoint->n_to_xy($n);

    my $x = $x1+$x2;    # midpoint*2
    my $y = $y1+$y2;
    ($x,$y) = (($x+$y-1)/2,
               ($x-$y-1)/2);  # rotate -45 and shift

    print "$n  $x,$y   $mx,$my\n";
  }
  exit 0;
}

{
  # grid X,Y offset
  require Math::PlanePath::AlternatePaperMidpoint;
  my $path = Math::PlanePath::AlternatePaperMidpoint->new (arms => 8);

  my %dxdy_to_digit;
  my %seen;
  for (my $n = 0; $n < 4**4; $n++) {
    my $digit = $n % 4;

    foreach my $arm (0 .. 7) {
      my ($x,$y) = $path->n_to_xy(8*$n+$arm);
      my $nb = int($n/4);
      my ($xb,$yb) = $path->n_to_xy(8*$nb+$arm);

      $xb *= 2;
      $yb *= 2;
      my $dx = $xb - $x;
      my $dy = $yb - $y;

      my $dxdy = "$dx,$dy";
      my $show = "${dxdy}[$digit]";
      $seen{$x}{$y} = $show;
      if ($dxdy eq '0,0') {
      }
      $dxdy_to_digit{$dxdy} = $digit;
    }
  }

  foreach my $y (reverse -45 .. 45) {
    foreach my $x (-5 .. 5) {
      printf " %9s", $seen{$x}{$y}//'e'
    }
    print "\n";
  }
  ### %dxdy_to_digit

  exit 0;
}

{
  # sum/sqrt(n) goes below pi/4
  print "pi/4 ",pi/4,"\n";
  require Math::PlanePath::AlternatePaper;
  my $path = Math::PlanePath::AlternatePaper->new;
  my $min = 999;
  for my $n (1 .. 102400) {
    my ($x,$y) = $path->n_to_xy($n);
    my $sum = $x+$y;
    my $frac = $sum/sqrt($n);
    #    printf "%10s %.4f\n", "$n,$x,$y", $frac;
    $min = min($min,$frac);
  }
  print "min  $min\n";
  exit 0;
}

{
  # repeat points
  require Math::PlanePath::AlternatePaper;
  require Math::BaseCnv;
  my $path = Math::PlanePath::AlternatePaper->new;
  for my $nn (0 .. 1024) {
    my ($x,$y) = $path->n_to_xy($nn);

     next unless $y == 18;

    my ($n,$m) = $path->xy_to_n_list($x,$y);
    next unless ($n == $nn) && $m;

    my $diff = $m - $n;
    my $xor = $m ^ $n;
    my $n4 = Math::BaseCnv::cnv($n,10,4);
    my $m4 = Math::BaseCnv::cnv($m,10,4);
    my $diff4 = Math::BaseCnv::cnv($diff,10,4);
    my $xor4 = Math::BaseCnv::cnv($xor,10,4);
    printf "%10s %6s %6s %6s,%-6s\n",
      "$n,$x,$y", $n4, $m4, $diff4, $diff4;
  }
  exit 0;
}

{
  # dY
  require Math::PlanePath::AlternatePaper;
  require Math::BaseCnv;
  my $path = Math::PlanePath::AlternatePaper->new;
  for (my $n = 1; $n <= 64; $n += 2) {
    my $n2 = Math::BaseCnv::cnv($n,10,2);
    my $n4 = Math::BaseCnv::cnv($n,10,4);
    my $dy = path_n_dy ($path, $n);

    my $nhalf = $n>>1;
    my $grs_half = GRS($nhalf);
    my $calc_dy = $grs_half * (($nhalf&1) ? -1 : 1);
    my $diff = ($calc_dy == $dy ? '' : '  ****');

    my $grs = GRS($n);

    printf "%10s %10s  %2d %2d %2d%s\n", $n2, $n4,
      $dy,
        $grs,
          $calc_dy,$diff;
  }
  exit 0;


  sub GRS {
    my ($n) = @_;
    return (count_1_bits($n&($n>>1)) & 1 ? -1 : 1);
  }
  sub count_1_bits {
    my ($n) = @_;
    my $count = 0;
    while ($n) {
      $count += ($n & 1);
      $n >>= 1;
    }
    return $count;
  }
}


{
  # base4 X,Y axes and diagonal
  # diagonal base4 all twos
  require Math::PlanePath::AlternatePaper;
  require Math::BaseCnv;
  my $path = Math::PlanePath::AlternatePaper->new;
  for my $x (0 .. 40) {
    my $y;
    $y = 0;
    $y = $x;

    my $n = $path->xy_to_n($x,$y);
    my $n2 = Math::BaseCnv::cnv($n,10,2);
    my $n4 = Math::BaseCnv::cnv($n,10,4);
    printf "%14s %10s  %4d  %d,%d\n",
      $n2, $n4, $n,$x,$y;
  }
  exit 0;
}




{
  # dX
  require Math::PlanePath::AlternatePaper;
  require Math::BaseCnv;
  my $path = Math::PlanePath::AlternatePaper->new;
  for (my $n = 0; $n <= 64; $n += 2) {
    my $n2 = Math::BaseCnv::cnv($n,10,2);
    my $n4 = Math::BaseCnv::cnv($n,10,4);
    my ($dx,$dy) = $path->n_to_dxdy($n);

    my $grs = GRS($n);
    my $calc_dx = 0;
    my $diff = ($calc_dx == $dx ? '' : '  ****');
    printf "%10s %10s  %2d %2d %2d%s\n", $n2, $n4,
      $dx,
        $grs,
          $calc_dx,$diff;
  }
  exit 0;
}

{
  # plain    rev
  # 0   0   0 -90
  # 1 +90   1   0
  # 2   0   2 +90
  # 3 -90   3   0
  #
  # dX ends even so plain, count 11 bits mod 2
  # dY ends odd so rev,

  # dX,dY
  require Math::PlanePath::AlternatePaper;
  require Math::BaseCnv;
  my $path = Math::PlanePath::AlternatePaper->new;
  for (my $n = 0; $n <= 128; $n += 2) {
    my ($x,$y) = $path->n_to_xy($n);
    my ($next_x,$next_y) = $path->n_to_xy($n+1);
    my $dx = $next_x - $x;
    my $dy = - path_n_dy ($path,$n ^ 0xFFFF);

    my $n2 = Math::BaseCnv::cnv($n,10,2);
    my $n4 = Math::BaseCnv::cnv($n,10,4);
    printf "%10s %10s  %2d,%2d\n", $n2, $n4, $dx,$dy;
  }
  exit 0;

  sub path_n_dx {
    my ($path,$n) = @_;
    my ($x,$y) = $path->n_to_xy($n);
    my ($next_x,$next_y) = $path->n_to_xy($n+1);
    return $next_x - $x;
  }
  sub path_n_dy {
    my ($path,$n) = @_;
    my ($x,$y) = $path->n_to_xy($n);
    my ($next_x,$next_y) = $path->n_to_xy($n+1);
    return $next_y - $y;
  }
}

# return 1 for left, 0 for right
sub path_n_turn {
  my ($path, $n) = @_;
  my $prev_dir = path_n_dir ($path, $n-1);
  my $dir = path_n_dir ($path, $n);
  my $turn = ($dir - $prev_dir) % 4;
  if ($turn == 1) { return 1; }
  if ($turn == 3) { return 0; }
  die "Oops, unrecognised turn";
}
# return 0,1,2,3
sub path_n_dir {
  my ($path, $n) = @_;
  my ($x,$y) = $path->n_to_xy($n);
  my ($next_x,$next_y) = $path->n_to_xy($n+1);
  return dxdy_to_dir4 ($next_x - $x,
                      $next_y - $y);
}
# return 0,1,2,3, with Y reckoned increasing upwards
sub dxdy_to_dir4 {
  my ($dx, $dy) = @_;
  if ($dx > 0) { return 0; }  # east
  if ($dx < 0) { return 2; }  # west
  if ($dy > 0) { return 1; }  # north
  if ($dy < 0) { return 3; }  # south
}
