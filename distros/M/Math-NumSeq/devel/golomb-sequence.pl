#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

require 5;
use strict;
use Math::NumSeq::GolombSequence;

# uncomment this to run the ### lines
#use Smart::Comments;

{
  # asymptotic ratio
  # squares a(n)/n oscillates up and down a bit
  my $seq;
  $seq = Math::NumSeq::GolombSequence->new (using_values => 'odd');
  $seq = Math::NumSeq::GolombSequence->new (using_values => 'all');
  $seq = Math::NumSeq::GolombSequence->new (using_values => 'even');
  $seq = Math::NumSeq::GolombSequence->new (using_values => '3k');
  $seq = Math::NumSeq::GolombSequence->new (using_values => 'squares');
  my $target = 1;
  my $prev;
  my $prev_frac = 0;
  for (;;) {
    my ($i,$value) = $seq->next or last;
    if ($prev != $value) {
      $prev = $value;
      my $frac = ($value / $i) / sqrt(2);
      if ($frac < $prev_frac) {
        printf "%6d  %d  %.10f %.10f\n", $i, $value, $prev_frac, $frac;
      } else {
        print "*\n";
      }
      $prev_frac = $frac;
    }
    # if ($i >= $target) {
    #   # $target = ($target+1)*1.1;
    #   $target++;
    #   my $frac = ($value / $i) / sqrt(2);
    #   my $flag = '';
    #   printf "%6d  %d  %.6f %s\n", $i, $value, $frac, $flag;
    # }
  }
  exit 0;
}

{
  # asymptotics, ith_estimate() and difference

  use constant PHI => (1 + sqrt(5)) / 2;
  my $seq;
  $seq = Math::NumSeq::GolombSequence->new (using_values => 'odd');
  $seq = Math::NumSeq::GolombSequence->new (using_values => 'all');
  $seq = Math::NumSeq::GolombSequence->new (using_values => 'even');
  $seq = Math::NumSeq::GolombSequence->new (using_values => '3k');
  $seq = Math::NumSeq::GolombSequence->new (using_values => 'squares');
  my $target = 1;
  for (;;) {
    my ($i,$value) = $seq->next or last;
    if ($i >= $target) {
      $target = ($target+1)*1.1;
      # $target++;
      my $est = ith_estimate($seq,$i);
      my $diff = $est - $value;
      my $frac = $est / $value;
      my $flag = ($diff > 2 || $diff < -2 ? '  ***' : '');
      # my $flag = ($diff >= 0.6 || $diff < -0.4 ? '  ***' : '');
      printf "%6d  %d %.2f  %.2f %.4f %s\n", $i, $value, $est, $diff, $frac, $flag;
      if ($diff > 3 || $diff < -3) {
      }
    }
  }

  # Vardi
  sub ith_estimate {
    my ($self, $i) = @_;
    if ($self->{'using_values'} eq 'all') {
      # 279949172  199757 199713.87  -43.13  ***
      return PHI**(2 - PHI) * $i**(PHI-1);  # plus O( n^(phi-1) / log(n) )
    }
    if ($self->{'using_values'} eq 'odd') {
      # A080605(n)=tau^(2-tau)*(2n)^(tau-1)+O(1)
      # Vardy method gives  O(n^(tau-1)/log(n)) instead of O(1).
      # 130598349  190615 191336.70  721.70  ***
      # 143658185  202185 202945.94  760.94  ***
      # 279949172  305449 306517.30  1068.30  ***
      return PHI**(2 - PHI) * (2*$i)**(PHI-1);  # plus O(n^(PHI-1)/log(n))
    }
    if ($self->{'using_values'} eq 'even') {
      # a(n) is asymptotic to tau^(2-tau)*(2n)^(tau-1)
      return PHI**(2 - PHI) * (2*$i)**(PHI-1);

      #  a(n)=round(tau^(2-tau)*(2n)^(tau-1))
      #  +(-1, +0 or +1)
    }
    if ($self->{'using_values'} eq '3k') {
      # a(n) is asymptotic to tau^(2-tau)*(3n)^(tau-1)
      return PHI**(2 - PHI) * (3*$i)**(PHI-1);
    }
    if ($self->{'using_values'} eq 'squares') {
      # a(n)/n -> sqrt(2)
      return $i*sqrt(2);
    }
    return 0;
  }
  exit 0;
}

{
  require Math::NumSeq::OEIS::File;
  my $hi = 30;
  my $seqstr;
  {
    my $seq = Math::NumSeq::GolombSequence->new (using_values => '3k');
    # $seq = Math::NumSeq::OEIS::File->new (anum => 'A080606');
    for (1 .. $hi) {
      my ($i,$value) = $seq->next or last;
      $seqstr .= "$value,";
    }
    print "$seqstr\n";
  }
  my $repstr;
  {
    my $seq = Math::NumSeq::GolombSequence->new (using_values => '3k');
    # $seq = Math::NumSeq::OEIS::File->new (anum => 'A080606');
    my $count = 1;
    my (undef,$prev) = $seq->next;
    OUTER: for (1 .. $hi) {
      for (;;) {
        my ($i,$value) = $seq->next or last OUTER;
        if ($value == $prev) {
          $count++;
        } else {
          ### $prev
          ### $value
          ### $count
          $repstr .= "$count,";
          $count = 1;
          $prev = $value;
          last;
        }
      }
    }
    print "final count $count\n";
    print "$repstr\n";
  }
  if ($repstr ne $seqstr) {
    print "different\n";
  }
  exit 0;
}

{
  my $start = 2;
  my $inc = 2;
  my @small = ($start) x $start;
  my $value = $start;
  foreach my $i (1 .. $#small) {
    $value += $inc;
    push @small, ($value) x $small[$i];
  }

  print join(' ',@small),"\n";
  exit 0;

  # 12, 12, 12, 14, 14, 14, 14, 14, 14, 16, 16, 16, 16, 16, 16, 18, 18, 18,
  # 18, 18, 18, 18, 18, 20, 20, 20, 20, 20, 20, 20, 20, 22, 22, 22, 22, 22,
  # 22, 22, 22, 24, 24, 24, 24, 24, 24, 24, 24, 26, 26, 26, 26, 26
}

{
  print "2 2 4 4 6 6 6 6 8 8 8 8 10 10 10 10 10 10 12 12 12,\n";

  my @a = (1, 2, 2, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 6, 7, 7, 7, 7, 8, 8, 8, 8, 9);
  @a = map {(2*$_,2*$_)} @a;
  print join(' ',@a),"\n";
  exit 0;

  # 12, 12, 12, 14, 14, 14, 14, 14, 14, 16, 16, 16, 16, 16, 16, 18, 18, 18,
  # 18, 18, 18, 18, 18, 20, 20, 20, 20, 20, 20, 20, 20, 22, 22, 22, 22, 22,
  # 22, 22, 22, 24, 24, 24, 24, 24, 24, 24, 24, 26, 26, 26, 26, 26
}


__END__

        Values                            Run Lengths
 1,                                           1
 3,  3,  3,                                   3
 5,  5,  5,                                   3
 7,  7,  7,                                   3
 9,  9,  9,  9,  9,                           5
11, 11, 11, 11, 11,                           5
13, 13, 13, 13, 13,                           5
15, 15, 15, 15, 15, 15, 15,                   7
17, 17, 17, 17, 17, 17, 17,                   7
19, 19, 19, 19, 19, 19, 19,                   7
21, 21, 21, 21, 21, 21, 21, 21, 21,           9
23, 23, 23, 23, 23, 23, 23, 23, 23, 23,      10
25, 25, 25, 25, 25, 25, 25, 25, 25            9


