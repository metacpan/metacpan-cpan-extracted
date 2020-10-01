#!/usr/bin/perl -w

# Copyright 2011, 2012, 2015, 2019, 2020 Kevin Ryde

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
use Math::BaseCnv 'cnv';
use Math::Prime::XS 0.23 'is_prime'; # version 0.23 fix for 1928099
use Math::PlanePath::GrayCode;
use Math::PlanePath::Base::Digits
  'digit_split_lowtohigh',
  'digit_join_lowtohigh';
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;



{
  # binary Gray twice cf base 4

  foreach my $n (0 .. 16) {
    my $b  = to_gray_reflected($n,2);
    my $b2 = to_gray_reflected($b,2);
    my $fr = to_gray_reflected($n,4);
    my $fm = to_gray_modular($n,4);
    printf "%5d %5d %5d\n",
      cnv($b2,10,4),
      cnv($fr,10,4),
      cnv($fm,10,4);
  }
  exit 0;
}


{
  # F. J. Budden and T. M. Sporton, "Some Unsolved Problems on Binary Codes",
  # Mathematics in School, volume 11, number 3, May 1982, pages 26-28.
  # http://www.jstor.org/stable/30213735

  # 14,32,50,114
  # 2* of
  # A295921  (n+2) * 2^(n-2) + 1
  #  maximal cliques in folded cube graph n
  # folded cube = merge antipodals
  #

  # 6,5  10mins len 50

  my $N  = 6;
  my $MD = 5;
  my @last = map {[-99]} 0 .. $N;
  ### @last
  my @seq = (-1);
  my @values = (0);
  my %values = (0 => 1);
  my $limit = 2**$N;
  my @flip = map {1<<$_} 0 .. $N-1;
  ### @flip
  my $new_value;
  my @max_seq;
  my @max_values;
  for (;;) {
    ### at: join('',@seq).' last '.join(',',map {$_->[-1]} @last).' values '.join(',',@values)

    if (0) {
      foreach my $i (0 .. $N-1) {
        my $s1 = join(',',@{$last[$i]});
        my $s2 = join(',',-99,grep {$seq[$_]==$i} 0 .. $#seq-1);
        unless ($s1 eq $s2) {
          print "i=$i\n";
          print "  $s1\n";
          print "  $s2\n";
          die;
        }
      }
      my @stepped_values = (0);
      foreach my $i (0 .. $#seq-1) {
        push @stepped_values, $stepped_values[-1] ^ $flip[$seq[$i]];
      }
      my $s1 = join(',',@stepped_values);
      my $s2 = join(',',@values);
      unless ($s1 eq $s2) {
        print "  $s1\n";
        print "  $s2\n";
        die;
      }
    }

    my $this = ++$seq[-1];
    if ($this >= $N) {
      ### backtrack ...
      pop @seq;
      last unless @seq;
      pop @{$last[$seq[-1]]};
      undef $values{pop @values};
      next;
    }
    my $dist = scalar(@seq) - $last[$this]->[-1];
    ### $dist
    if ($dist > $MD
        && !$values{$new_value = $values[-1] ^ $flip[$this]}) {
      ### descend to: $this
      $values{$new_value} = 1;
      push @values, $new_value;
      if (@seq > @max_seq) {
        @max_seq = @seq;
        @max_values = @values;
        print "new high ",scalar(@max_values),"\n";
      }
      if (@values == $limit) {
        print "found $limit\n";
        print "  ",join('',@seq),"\n";
        last;
      }
      push @{$last[$this]}, $#seq;
      push @seq, -1;
    }
  }
  my $max = scalar(@max_values);
  print "max $max seq ",join('',@max_seq),"\n";
  foreach my $i (0 .. $#max_values) {
    printf "  %0*b  %s\n", $N, $max_values[$i], $max_seq[$i] // '[none]';
  }
  exit 0;
}

{
  my $from = from_gray(2**8-1,2);
  require Math::BaseCnv;
  print Math::BaseCnv::cnv($from,10,2),"\n";
  exit 0;
}
{
  # turn Left
  # 1,1,0,0,1,1,1,
  # left at N=1,2 then 180 at N=3
  # 7to8 
  # N=2,3,4 same Y
  # parity of A065883

  require Math::NumSeq::PlanePathTurn;
  my $planepath;
  $planepath = "GrayCode";
  my $seq = Math::NumSeq::PlanePathTurn->new (planepath => $planepath,
                                              turn_type => 'LSR');
  my $path = $seq->{'planepath_object'};
  for (1 .. 60) {
    my ($n, $turn) = $seq->next;
    # next if $value;

    my ($x,$y) = $path->n_to_xy($n);
    my ($dx,$dy) = $path->n_to_dxdy($n);
    my $calc = calc_left_turn($n);
    print "$n  $x,$y  $turn $calc  dxdy=$dx,$dy\n";
    # printf "%d,", $value;

    # printf "  i-1 gray %6b\n",to_gray($n-1,2);
    # printf "  i   gray %6b\n",to_gray($n,2);
    # printf "  i+1 gray %6b\n",to_gray($n+1,2);
  }
  print "\n";
  exit 0;

  sub calc_left_turn {
    my ($n) = @_;
    return count_low_0_bits(($n+1)>>1) % 2 ? 0 : 1;
  }
  sub count_low_1_bits {
    my ($n) = @_;
    my $count = 0;
    while ($n % 2) {
      $count++;
      $n = int($n/2);
    }
    return $count;
  }
  sub count_low_0_bits {
    my ($n) = @_;
    if ($n == 0) { die; }
    my $count = 0;
    until ($n % 2) {
      $count++;
      $n /= 2;
    }
    return $count;
  }
}

{
  # cf GRS
  require Math::NumSeq::GolayRudinShapiro;
  require Math::NumSeq::DigitCount;
  my $seq = Math::NumSeq::GolayRudinShapiro->new;

  my $dc = Math::NumSeq::DigitCount->new (radix => 2);

  for (my $n = 0; $n < 2000; $n++) {
    my $grs = $seq->ith($n);
    my $gray = from_binary_gray($n);
    my $gbit = $dc->ith($gray) & 1;
    printf "%3d  %2d %2d\n", $n, $grs, $gbit;
  }
  exit 0;
}
{
  # X,Y,Diagonal values
  foreach my $apply_type ('TsF','Ts','sT','sF') {
    print "$apply_type\n";
    my $path = Math::PlanePath::GrayCode->new (apply_type => $apply_type);
    foreach my $i (0 .. 40) {
      my $nx = $path->xy_to_n(0,$i);
      printf "%d  %d %b\n", $i, $nx, $nx;
    }
  }
  exit 0;
}

{
  # path sameness

  require Tie::IxHash;
  my @apply_types = ('TsF','Ts','Fs','FsT','sT','sF');
  my @gray_types = ('reflected',
                     'modular',
                   );
  for (my $radix = 2; $radix <= 10; $radix++) {
    print "radix $radix\n";

    my %xy;
    tie %xy, 'Tie::IxHash';
    foreach my $apply_type (@apply_types) {
      foreach my $gray_type (@gray_types) {
        my $path = Math::PlanePath::GrayCode->new
          (radix      => $radix,
           apply_type => $apply_type,
           gray_type  => $gray_type);

        my $str = '';
        foreach my $n (0 .. $radix ** 4) {
          my ($x,$y) = $path->n_to_xy($n);
          $str .= " $x,$y";
        }
        push @{$xy{$str}}, "$apply_type,$gray_type";
      }
    }
    my @distinct;
    foreach my $aref (values %xy) {
      if (@$aref > 1) {
        print "  same: ",join('   ',@$aref),"\n";
      } else {
        push @distinct, @$aref;
      }
    }
    print "  distinct: ",join('   ',@distinct),"\n";
  }
  exit 0;
}

{
  # to_gray() same as from_gray() in some radices

  for (my $radix = 2; $radix < 20; $radix++) {
    my $result = "same";
    for (my $n = 0; $n < 2000; $n++) {
      my $to = to_gray($n,$radix);
      my $from = from_gray($n,$radix);
      if ($to != $from) {
        $result = "different";
        last;
      }
    }
    print "radix=$radix   to/from  $result\n";
  }
  exit 0;

  sub to_gray {
    my ($n, $radix) = @_;
    my $digits = [ digit_split_lowtohigh($n,$radix) ];
    Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,$radix);
    return digit_join_lowtohigh($digits,$radix);
  }
  sub from_gray {
    my ($n, $radix) = @_;
    my $digits = [ digit_split_lowtohigh($n,$radix) ];
    Math::PlanePath::GrayCode::_digits_from_gray_reflected($digits,$radix);
    return digit_join_lowtohigh($digits,$radix);
  }
}

{
  for (my $n = 0; $n < 2000; $n++) {
    next unless is_prime($n);
    my $gray = to_binary_gray($n);
    next unless is_prime($gray);
    printf "%3d  %3d\n", $n, $gray;
  }
  exit 0;

  sub to_binary_gray {
    my ($n) = @_;
    my $digits = [ digit_split_lowtohigh($n,2) ];
    Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,2);
    return digit_join_lowtohigh($digits,2);
  }
}

{
  my $radix = 10;
  my $num = 3;
  my $width = length($radix)*2*$num;
  foreach my $i (0 .. $radix ** $num - 1) {

    my $i_digits = [ digit_split_lowtohigh($i,$radix) ];

    my @gray_digits = @$i_digits;
    my $gray_digits = \@gray_digits;
    Math::PlanePath::GrayCode::_digits_to_gray_reflected($gray_digits,$radix);
    # Math::PlanePath::GrayCode::_digits_to_gray_modular($gray_digits,$radix);

    my @rev_digits = @gray_digits;
    my $rev_digits = \@rev_digits;
    Math::PlanePath::GrayCode::_digits_from_gray_reflected($rev_digits,$radix);
    # Math::PlanePath::GrayCode::_digits_from_gray_modular($rev_digits,$radix);

    my $i_str    = join(',', reverse @$i_digits);
    my $gray_str = join(',', reverse @$gray_digits);
    my $rev_str  = join(',', reverse @$rev_digits);
    my $diff = ($i_str eq $rev_str ? '' : '   ***');

    printf "%*s  %*s   %*s%s\n",
      $width,$i_str, $width,$gray_str, $width,$rev_str,
        $diff;
  }
  exit 0;
}

{
  foreach my $i (0 .. 32) {
    printf "%05b  %05b\n", $i, from_binary_gray($i);
  }
  sub from_binary_gray {
    my ($n) = @_;
    my @digits;
    while ($n) {
      push @digits, $n & 1;
      $n >>= 1;
    }
    my $xor = 0;
    my $ret = 0;
    while (@digits) {
      my $digit = pop @digits;
      $ret <<= 1;
      $ret |= $digit^$xor;
      $xor ^= $digit;
    }
    return $ret;
  }
  exit 0;
}

# integer modular
#  000     000
#  001     001
#  002     002
#  010     012
#  011     010
#  012     011
#  020     021
#  021     022
#  022     020

# integer reflected
#  000     000
#  001     001
#  002     002
#  010     012
#  011     011
#  012     010
#  020     020
#  021     021
#  022     022
#  100     122
#  101     121
#  102     120
#  110     110
#  111     111
#  112     112
#  120     102
#  121     101
#  122     100
#
#  200     200


# A128173  ternary reverse
# 0,    000
# 1,    001
# 2,    002
# 5,    012
# 4,    011
# 3,    010
# 6,    020
# 7,    021
# 8,    022
# 17,   122
# 16,   121
# 15,   120
# 12,   110
# 13,   111
# 14,   112
# 11,   102
# 10,   101
# 9,    100
# 18,   200
           
# A105530  ternary cyclic
# 0,    000
# 1,    001
# 2,    002
# 5,    012
# 3,    010
# 4,    011
# 7,    021
# 8,    022
# 6,    020
# 15,   120
# 16,   121
# 17,   122
# 11,   102
# 9,    100
# 10,   101
# 13,   111
# 14,   112
# 12,   110
# 21,   210
# 22,   211 
#     


sub _to_gray {
  my ($n) = @_;
  ### _to_gray(): $n
  return ($n >> 1) ^ $n;
}
sub _from_gray {
  my ($n) = @_;
  ### _from_gray(): $n
  my $shift = 1;
  for (;;) {
    my $xor = ($n >> $shift) || return $n;
    $n ^= $xor;
    $shift *= 2;
  }

  # my @digits;
  # while ($n) {
  #   push @digits, $n & 1;
  #   $n >>= 1;
  # }
  # my $xor = 0;
  # my $ret = 0;
  # while (@digits) {
  #   my $digit = pop @digits;
  #   $ret <<= 1;
  #   $ret |= $digit^$xor;
  #   $xor ^= $digit;
  # }
  # return $ret;
}

sub to_gray_reflected {
  my ($n, $radix) = @_;
  my $digits = [ digit_split_lowtohigh($n,$radix) ];
  Math::PlanePath::GrayCode::_digits_to_gray_reflected($digits,$radix);
  return digit_join_lowtohigh($digits,$radix);
}
sub from_gray_reflected {
  my ($n, $radix) = @_;
  my $digits = [ digit_split_lowtohigh($n,$radix) ];
  Math::PlanePath::GrayCode::_digits_from_gray_reflected($digits,$radix);
  return digit_join_lowtohigh($digits,$radix);
}

sub to_gray_modular {
  my ($n, $radix) = @_;
  my $digits = [ digit_split_lowtohigh($n,$radix) ];
  Math::PlanePath::GrayCode::_digits_to_gray_modular($digits,$radix);
  return digit_join_lowtohigh($digits,$radix);
}
sub from_gray_modular {
  my ($n, $radix) = @_;
  my $digits = [ digit_split_lowtohigh($n,$radix) ];
  Math::PlanePath::GrayCode::_digits_from_gray_modular($digits,$radix);
  return digit_join_lowtohigh($digits,$radix);
}

