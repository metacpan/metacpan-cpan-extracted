#!/usr/bin/perl -w

# Copyright 2012, 2020 Kevin Ryde

# This file is part of Math-NumSeq-Alpha.
#
# Math-NumSeq-Alpha is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq-Alpha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq-Alpha.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;

use Test;
plan tests => 55;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::DigitCount;
use Math::NumSeq::SevenSegments;

# uncomment this to run the ### lines
# use Smart::Comments '###';


# Other things:
#
# A000787 Strobogrammatic = same in 180 degree rotation
# A018846 Strobogrammatic, 7-segments
# A018848 same upside down squares, not seven seg
# A018847 same upside down primes
# A018849 same upside down squares, seven-seg
# A053701 vertically symmetric
# A007284 horizontally symmetric
# A027389 count endpoints of digits, so 0 has none, 6 has one, others have 2


#------------------------------------------------------------------------------
# A165244 - digits sorted by num segments
# 1,          2
# 7,          3
# 4,          4
# 2, 3, 5,    5
# 0, 6, 9,    6
# 8           7
# A006942, A074458, A010371.

foreach my $elem ([6,3,6],    # A006942
                  # [6,3,5],  # no, moves 9 down earlier

                  # [5,3,5],  # no, moves 6 before 0
                  # [5,3,6],  #

                  # [6,4,6],  # no, moves 7 down before 4
                  # [6,4,5],
                  # [5,4,5],
                  # [5,4,6],
                 ) {
  my ($six,$seven,$nine) = @$elem;
  my $seq = Math::NumSeq::SevenSegments->new
    (six=>$six, seven=>$seven, nine=>$nine);
  ok ($seq->{'digit_segments'}->{'6'}, $six);
  ok ($seq->{'digit_segments'}->{'7'}, $seven);
  ok ($seq->{'digit_segments'}->{'9'}, $nine);

  MyOEIS::compare_values
      (anum => 'A165244',
       name => "variant $six,$seven,$nine",
       func => sub {
         my ($count) = @_;
         my @got = sort {$seq->ith($a) <=> $seq->ith($b)
                           || $a <=> $b} 0 .. 9;
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A216261 number smallest needing n segments.
#
# Defined for A006942 6,3,6.
#
# Also for A277116 6,3,5 since its 9 is never a candidate, as 5 or 6
# segments always bettered by 2 or 0 or 6.

# But variation digit 7 with 4 segments is different, since then no 3.
{ my $seq = Math::NumSeq::SevenSegments->new (seven=>4);
  ok (join(',',map {$seq->ith($_)} 0..9), '6,2,5,5,4,5,6,4,7,5');
}

foreach my $elem ([6,3,6],  # definition of A216261
                  [6,3,5],
                  [5,3,5],  # different
                  [5,3,6],  # different
                 ) {
  my ($six,$seven,$nine) = @$elem;
  my $seq = Math::NumSeq::SevenSegments->new
    (six=>$six, seven=>$seven, nine=>$nine);
  ok ($seq->{'digit_segments'}->{'6'}, $six);
  ok ($seq->{'digit_segments'}->{'7'}, $seven);
  ok ($seq->{'digit_segments'}->{'9'}, $nine);

  MyOEIS::compare_values
      (anum => 'A216261',
       name => "variant $six,$seven,$nine",
       max_count => 30,   # naive search is a bit slow
       func => sub {
         my ($count) = @_;
         my $min = 2;
         my $max = $min + $count - 1;
         my @got;
         my $got = 0;
         $seq->rewind;
         while ($got < $count) {
           my ($i,$value) = $seq->next;
           ### $i
           ### $value
           my $pos = $value-$min;
           if ($pos < $count && ! defined $got[$pos]) {
             $got[$pos] = $i;
             $got++;
           }
         }
         return \@got;
       });
}


#------------------------------------------------------------------------------
# A038619 - first m needing more segments than any previous
# 1,2,6,8,10,18,20
# digit 6 is 6, so 9 irrelevant

foreach my $elem ([6,3,6],    # A006942
                  [6,3,5],    # A277116
                  # [5,3,5],  # different (A063720)
                  # [5,3,6],  # different

                  [6,4,6],    # A010371
                  [6,4,5],    # A074458
                  # [5,4,5],  # different
                  # [5,4,6],  # different
                 ) {
  my ($six,$seven,$nine) = @$elem;
  my $seq = Math::NumSeq::SevenSegments->new
    (six=>$six, seven=>$seven, nine=>$nine);
  ok ($seq->{'digit_segments'}->{'6'}, $six);
  ok ($seq->{'digit_segments'}->{'7'}, $seven);
  ok ($seq->{'digit_segments'}->{'9'}, $nine);

  MyOEIS::compare_values
      (anum => 'A038619',
       name => "variant $six,$seven,$nine",
       max_count => 30,   # naive search is a bit slow
       func => sub {
         my ($count) = @_;
         my $m = 0;
         my @got;
         $seq->rewind;
         $seq->seek_to_i(1);
         while (@got < $count) {
           my ($i,$value) = $seq->next;
           if ($value > $m) { push @got, $i; $m = $value; };
         }
         return \@got;
       });
}

#------------------------------------------------------------------------------
# A063720 - 5,3,5

{
  my $seq = Math::NumSeq::SevenSegments->new (six => 5);
  ok ($seq->{'digit_segments'}->{'6'}, 5);
  ok ($seq->{'digit_segments'}->{'7'}, 3);
  ok ($seq->{'digit_segments'}->{'9'}, 5);

  MyOEIS::compare_values
      (anum => 'A063720',
       func => sub {
         my ($count) = @_;
         return [ map {$seq->ith($_)} 0 .. $count-1 ];
       });
}



#------------------------------------------------------------------------------
# A277116 - default, 6,3,5

{
  my $seq = Math::NumSeq::SevenSegments->new;
  ok ($seq->{'digit_segments'}->{'6'}, 6);
  ok ($seq->{'digit_segments'}->{'7'}, 3);
  ok ($seq->{'digit_segments'}->{'9'}, 5);

  MyOEIS::compare_values
      (anum => 'A277116',
       func => sub {
         my ($count) = @_;
         return [ map {$seq->ith($_)} 0 .. $count-1 ];
       });
}

#------------------------------------------------------------------------------
# A006942 - 6,3,6

{
  my $seq = Math::NumSeq::SevenSegments->new (nine => 6);
  ok ($seq->{'digit_segments'}->{'6'}, 6);
  ok ($seq->{'digit_segments'}->{'7'}, 3);
  ok ($seq->{'digit_segments'}->{'9'}, 6);

  MyOEIS::compare_values
      (anum => 'A006942',
       func => sub {
         my ($count) = @_;
         return [ map {$seq->ith($_)} 0 .. $count-1 ];
       });
}

#------------------------------------------------------------------------------
# A074458 - 6,4,5

{
  my $seq = Math::NumSeq::SevenSegments->new (seven => 4);
  ok ($seq->{'digit_segments'}->{'6'}, 6);
  ok ($seq->{'digit_segments'}->{'7'}, 4);
  ok ($seq->{'digit_segments'}->{'9'}, 5);

  MyOEIS::compare_values
      (anum => 'A074458',
       func => sub {
         my ($count) = @_;
         return [ map {$seq->ith($_)} 0 .. $count-1 ];
       });
}

# A074459 - how many segments change   6,4,5
{
  # modified A234692 so that 9 is 5 segments
  my @segbits= (63, 6, 91, 79, 102, 109, 125, 39, 127, 0b1100111);
  my $bitcount = Math::NumSeq::DigitCount->new (radix => 2, digit => 1);
  MyOEIS::compare_values
      (anum => 'A074459',
       func => sub {
         my ($count) = @_;
         my @got;
         foreach my $n (1 .. $count) {
           my @n_digits = split //, $n;
           my @p_digits = split //, $n-1;
           while (@p_digits < @n_digits) { unshift @p_digits, 0 }
           @n_digits == @p_digits or die;
           my $total = 0;
           foreach my $i (0 .. $#n_digits) {
             $total += $bitcount->ith($segbits[$n_digits[$i]]
                                      ^ $segbits[$p_digits[$i]]);
           }
           push @got, $total;
         }
         return \@got;
       });
}


#------------------------------------------------------------------------------
# A010371 - 6,4,6

{
  my $seq = Math::NumSeq::SevenSegments->new (seven => 4,
                                              nine  => 6);
  ok ($seq->{'digit_segments'}->{'6'}, 6);
  ok ($seq->{'digit_segments'}->{'7'}, 4);
  ok ($seq->{'digit_segments'}->{'9'}, 6);
  ok ($seq->oeis_anum, 'A010371');

  MyOEIS::compare_values
      (anum => 'A010371',
       func => sub {
         my ($count) = @_;
         return [ map {$seq->ith($_)} 0 .. $count-1 ];
       });

  # A143616 - new high in A010371 6,4,5
  MyOEIS::compare_values
      (anum => 'A143616',
       max_count => 30,   # naive search is a bit slow
       func => sub {
         my ($count) = @_;
         my $m = 0;
         my @got;
         $seq->rewind;
         while (@got < $count) {
           my ($i,$value) = $seq->next;
           if ($value > $m) { push @got, $m=$value; };
         }
         return \@got;
       });

  # A143617 - new high positions in A010371 6,4,5
  MyOEIS::compare_values
      (anum => 'A143617',
       max_count => 30,   # naive search is a bit slow
       func => sub {
         my ($count) = @_;
         my $m = 0;
         my @got;
         $seq->rewind;
         while (@got < $count) {
           my ($i,$value) = $seq->next;
           if ($value > $m) { push @got, $i; $m = $value; };
         }
         return \@got;
       });

  # v=OEIS_samples("A143617"); v=v[20..#v];
  # recurrence_guess(v)
  # 1,0,0,0,0,0,10,-10
  # a(n+7) = 10*a(n) + 8 for n > 4;
  # a(n) = 10*a(n-7) + 8   for n-7 > 4
  # a(n) = 10*a(n-7) + 8   for n-7 > 4
  #
  # apply(t->9*t+8, [0,8,10,18,20,28,68,88,108,188,200])
  # vector(30,n,a(n))
  # GP-DEFINE  my(table=[0,8,10,18,20,28,68,88,108,188,200]); \
  # GP-DEFINE  a(n) = my(q=max(0,(n-5)\7), p=10^q); ((table[n-7*q]*9+8)*p - 8)/9
  #
  # GP-DEFINE  my(table=[8,80,98,170,188,260,620,800,980,1700,1808]); \
  # GP-DEFINE  a(n) = my(q=max(0,(n-5)\7), p=10^q); (table[n-7*q]*p - 8)/9
  # GP-DEFINE  { my(high=[188,260,620,800,980,1700,1808]);
  # GP-DEFINE    a(n) = if(n<5,[0,8,10,18][n],
  # GP-DEFINE      my(q,r); [q,r]=divrem(n-5,7); (high[r+1]*10^q - 8)/9); }
  # GP-Test  vector(1000,n,n+=4; a(n+7)) == \
  # GP-Test  vector(1000,n,n+=4; 10*a(n) + 8)
  #
  # my(v=OEIS_samples("A143617")); vector(#v,n, a(n)) == v  \\ OFFSET=1
  # my(g=OEIS_bfile_gf("A143617")); g==Polrev(vector(poldegree(g)+1,n,n--; if(n,a(n))))
  # poldegree(OEIS_bfile_gf("A143617"))


  # A234691 - bit patterns of segments for 0..9
  # is 6,4,6 per A010371
  my $bitcount = Math::NumSeq::DigitCount->new (radix => 2, digit => 1);
  ok ($seq->oeis_anum, 'A010371');
  MyOEIS::compare_values
      (anum => 'A234691',
       name => "A234691 bitcount",
       fixup => sub {
         my ($aref) = @_;
         # map bit patterns to just counts of 1-bits
         $aref->[5] = 107;
         foreach my $bits (@$aref) { $bits = $bitcount->ith($bits); }
       },
       func => sub {
         my ($count) = @_;
         return [ map {$seq->ith($_)} 0 .. $count-1 ];
       });
}

#------------------------------------------------------------------------------
exit 0;
