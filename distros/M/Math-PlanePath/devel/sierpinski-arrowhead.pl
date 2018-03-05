#!/usr/bin/perl -w

# Copyright 2011, 2012, 2018 Kevin Ryde

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
use Math::PlanePath::SierpinskiArrowhead;

# uncomment this to run the ### lines
use Smart::Comments;



{
  # turn
  # A189706 = ternary lowest non-1 and its position
  #   A189707 positions of 0s, A189708 positions of 1s
  # A156595 = ternary lowest non-2 and its position

  # GP-DEFINE  select_first_n(f,n) = {
  # GP-DEFINE    my(l=List([]), i=0);
  # GP-DEFINE    while(#l<n, if(f(i),listput(l,i)); i++);
  # GP-DEFINE    Vec(l);
  # GP-DEFINE  }

  # GP-DEFINE  A189706(n) = {  \\ but here offset 0 so n=0 first term
  # GP-DEFINE    my(ret=0);
  # GP-DEFINE    while(n%3==1, n\=3;ret=!ret);
  # GP-DEFINE    if(n%3==0,ret,!ret);
  # GP-DEFINE  }
  # vector(24,n,n--; A189706(n))  == \
  # [0,1,1, 0,0,1, 0, 0, 1, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0, 1, 1]

  use constant::defer A189707_ternary_flat => sub {
    require MyFLAT;
    require FLAT::Regex;
    return FLAT::Regex->new ('((0|1|2)* 0 | []) 1(11)* | (0|1|2)* 2(11)*')->as_dfa
      ->MyFLAT::minimize
      ->MyFLAT::set_name("A189707_ternary0");
  };
  use constant::defer A189708_ternary_flat => sub {
    require MyFLAT;
    require FLAT::Regex;
    return FLAT::Regex->new ('((0|1|2)* 0 | []) (11)* | (0|1|2)* 2 1(11)*')->as_dfa
      ->MyFLAT::minimize
      ->MyFLAT::set_name("A189708_ternary0");
  };
  use constant::defer ternary_any_flat => sub {
    require MyFLAT;
    require FLAT::Regex;
    return FLAT::Regex->new ('(0|1|2)*')->as_dfa
      ->MyFLAT::minimize
      ->MyFLAT::set_name("ternary any");
  };
  A189707_ternary_flat()->union(A189708_ternary_flat())->as_dfa
    ->equals(ternary_any_flat()) or die;

  # MyFLAT::FLAT_show_breadth(A189707_ternary_flat(),3);
  # MyFLAT::FLAT_show_breadth(A189708_ternary_flat(),3);
  # A189708_ternary_flat()->MyFLAT::reverse->MyFLAT::minimize->MyFLAT::view;

  # left = even+even or odd+odd
  my $f = FLAT::Regex->new ('(0|2)* (1 (0|2)* 1 (0|2)*)* (1|2) (00)*
                  | (0|2)* 1 (0|2)* (1 (0|2)* 1 (0|2)*)* (1|2) 0(00)*
                            ')->as_dfa
    ->MyFLAT::minimize;
  $f->MyFLAT::view;
  $f->MyFLAT::reverse->MyFLAT::minimize->MyFLAT::view;

  require Math::NumSeq::PlanePathTurn;
  require Math::BaseCnv;
  my $seq = Math::NumSeq::PlanePathTurn->new
    (planepath => 'SierpinskiArrowhead',
     turn_type => 'Left');
  foreach (1 .. 400) {
    my ($i, $value) = $seq->next;
    my $i3 = Math::BaseCnv::cnv($i,10,3);
    my $calc = $f->contains($i3) ? 1 : 0;
    my $diff = ($value == $calc ? "" : " ***");
    print "$i $i3 $value $calc$diff\n";
  }

  exit 0;
}

{
  # turn sequence

  require Math::NumSeq::PlanePathTurn;
  require Math::BaseCnv;
  my $seq = Math::NumSeq::PlanePathTurn->new
    (planepath => 'SierpinskiArrowhead',
     turn_type => 'Left');
  foreach (1 .. 400) {
    my ($i, $value) = $seq->next;
    my $i3 = Math::BaseCnv::cnv($i,10,3);
    # my $calc = calc_turnleft($i);
    my $calc = WORKING__calc_turnleft($i);
    my $diff = ($value == $calc ? "" : " ***");
    print "$i $i3 $value $calc$diff\n";
  }

  sub calc_turnleft {   # not working
    my ($n) = @_;
    my $ret = 1;
    my $flip = 0;
    while ($n && ($n % 9) == 0) {
      $n = int($n/9);
    }
    if ($n) {
      my $digit = $n % 9;
      my $flip = ($digit == 0
                  || $digit == 1     # 01
                  # || $digit == 3  # 10
                  || $digit == 5  # 12
                  || $digit == 6  # 20
                  || $digit == 7  # 21
                 );
      $ret ^= $flip;
      $n = int($n/9);
    }
    while ($n) {
      my $digit = $n % 9;
      my $flip = ($digit == 1     # 01
                  || $digit == 3  # 10
                  || $digit == 5  # 12
                  || $digit == 7  # 21
                 );
      $ret ^= $flip;
      $n = int($n/9);
    }
    return $ret;
  }

  # GP-DEFINE  CountLowZeros(n) = valuation(n,3);
  # vector(20,n, CountLowZeros(n))
  # GP-DEFINE  CountLowTwos(n) = my(ret=0); while(n%3==2, n\=3;ret++); ret;
  # GP-DEFINE  CountLowOnes(n) = my(ret=0); while(n%3==1, n\=3;ret++); ret;
  # GP-DEFINE  CountOnes(n) = vecsum(apply(d->d==1,digits(n,3)));
  # vector(20,n,n--; CountOnes(n))
  # GP-DEFINE  LowestNonZero(n) = {
  # GP-DEFINE    if(n<1,error("LowestNonZero() is for n>=1")); \
  # GP-DEFINE    (n / 3^valuation(n,3)) % 3;
  # GP-DEFINE  }
  # GP-DEFINE  LowestNonOne(n) = while((n%3)==1,n=n\3); n%3;
  # GP-DEFINE  LowestNonTwo(n) = while((n%3)==2,n=n\3); n%3;
  # GP-DEFINE  CountOnesExceptLowestNonZero(n) = {
  # GP-DEFINE    while(n && n%3==0, n/=3);
  # GP-DEFINE    CountOnes(n\3);
  # GP-DEFINE  }
  # vector(20,n,n--; CountOnes(n))

  # GP-DEFINE  turn_left(n) = ! turn_right(n);
  # GP-DEFINE  turn_right(n) = (CountOnes(n) + LowestNonZero(n) + CountLowZeros(n)) % 2;
  # GP-DEFINE  turn_right(n) = (CountOnesExceptLowestNonZero(n) + CountLowZeros(n)) % 2;
  # vector(20,n, turn_left(n))
  # vector(22,n, turn_right(n))
  # vector(15,n, turn_left(n)-turn_right(n))
  # not in OEIS: 1, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1, 0, 0, 1, 1, 1
  # not in OEIS: 0, 0, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0,1,1
  # not in OEIS: 1, 1, -1, -1, -1, -1, 1, 1, 1, -1, -1, 1, 1, 1, 1

  # at odd and even positions
  # vector(15,n, turn_left(2*n)-turn_right(2*n))
  # vector(18,n, turn_left(2*n-1)-turn_right(2*n-1))
  # not in OEIS: 1, -1, -1, 1, -1, 1, 1, -1, 1, 1, -1, -1, 1, -1, 1
  # not in OEIS: 1, -1, -1, 1, 1, -1, 1, 1, -1, 1, -1, -1, 1, -1, -1, 1, 1, -1

  # GP-Test  vector(1000,m,m--; ((LowestNonOne(m)==0)+CountLowOnes(m))%2) == \
  # GP-Test  vector(1000,m, turn_left(2*m-1))
  # GP-Test  vector(1000,m,m--; ((LowestNonOne(m)==2)+CountLowOnes(m))%2) == \
  # GP-Test  vector(1000,m,m--; turn_right(2*m+1))

  # GP-Test  vector(1000,m,m--; ((LowestNonTwo(m)==0)+CountLowTwos(m))%2) == \
  # GP-Test  vector(1000,m, turn_left(2*m))
  # GP-Test  vector(1000,m,m--; (LowestNonTwo(m)+CountLowTwos(m))%2) == \
  # GP-Test  vector(1000,m, turn_right(2*m))

  # GP-Test  vector(1000,m, (LowestNonZero(m)+CountLowZeros(m))%2) == \
  # GP-Test  vector(1000,m, turn_left(2*m))

  # GP-Test  vector(1000,n, (n + LowestNonZero(n) + CountLowZeros(n))%2) == \
  # GP-Test  vector(1000,n, turn_right(n))

  # vector(25,n, (1+LowestNonZero(n) + CountLowZeros(n))%2) 
  # is A189706 with index change low-2s -> low-0s

  # ternary
  # [ count 1 digits ] [1 or 2] [ count low 0 digits ]

  # vector(10,k, (3^k)%2)
  # vector(10,k, (2*3^k)%2)

  sub WORKING__calc_turnleft { # works
    my ($n) = @_;
    my $ret = 1;
    while ($n && ($n % 3) == 0) {
      $ret ^= 1;             # flip for trailing 0s
      $n = int($n/3);
    }
    $n = int($n/3);          # skip lowest non-0
    while ($n) {
      if (($n % 3) == 1) {   # flip for all 1s
        $ret ^= 1;
      }
      $n = int($n/3);
    }
    return $ret;
  }

  sub count_digits {
    my ($n) = @_;
    my $count = 0;
    while ($n) {
      $count++;
      $n = int($n/3);
    }
    return $count;
  }
  sub count_1_digits {
    my ($n) = @_;
    my $count = 0;
    while ($n) {
      $count += (($n % 3) == 1);
      $n = int($n/3);
    }
    return $count;
  }
  exit 0;
}


{
  # direction sequence

  # 9-17  = mirror image horizontally 3-dir
  # 18-26 = dir+2

  require Math::NumSeq::PlanePathDelta;
  require Math::BaseCnv;
  my $seq = Math::NumSeq::PlanePathDelta->new
    (planepath => 'SierpinskiArrowhead',
     delta_type => 'TDir6');
  foreach (1 .. 3**4+1) {
    my ($i, $value) = $seq->next;
    # $value %= 6;
    my $i3 = Math::BaseCnv::cnv($i,10,3);
    my $calc = calc_dir6($i);
    print "$i $i3 $value $calc\n";
  }

  sub calc_dir6 {   # works
    my ($n) = @_;
    my $dir = 1;

    while ($n) {
      if (($n % 9) == 0) {
      } elsif (($n % 9) == 1) {
        $dir = 3 - $dir;
      } elsif (($n % 9) == 2) {
        $dir = $dir + 2;

      } elsif (($n % 9) == 3) {
        $dir = 3 - $dir;
      } elsif (($n % 9) == 4) {
      } elsif (($n % 9) == 5) {
        $dir = 1 - $dir;

      } elsif (($n % 9) == 6) {
        $dir = $dir - 2;
      } elsif (($n % 9) == 7) {
        $dir = 1 - $dir;
      } elsif (($n % 9) == 8) {
      }
      $n = int($n/9);
    }
    return $dir % 6;
  }

  sub Xcalc_dir6 {  # works
    my ($n) = @_;
    my $dir = 1;

    while ($n) {
      if (($n % 3) == 0) {
      }
      if (($n % 3) == 1) {
        # mirror
        $dir = 3 - $dir;
      }
      if (($n % 3) == 2) {
        $dir = $dir + 2;
      }
      $n = int($n/3);


      if (($n % 3) == 0) {
      }
      if (($n % 3) == 1) {
        # mirror
        $dir = 3 - $dir;
      }
      if (($n % 3) == 2) {
        $dir = $dir - 2;
      }
      $n = int($n/3);
    }
    return $dir % 6;
  }
  exit 0;
}


