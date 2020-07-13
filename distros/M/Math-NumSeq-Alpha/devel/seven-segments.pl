#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde

# This file is part of Math-NumSeq-Alpha.
#
# Math-NumSeq-Alpha is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq-Alpha is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq-Alpha.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Math::BaseCnv 'cnv';
use Math::NumSeq::SevenSegments;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  my $seq = Math::NumSeq::SevenSegments->new;
  ### $seq
  foreach (0 .. 2) {
    my ($i,$value) = $seq->next;
    ### $i
    ### $value
  }
}
# " --0--   : bit 0,
# "1    2"  : bits 1+2,
#   --3--   
# "4    5"  : bit 5,
# " --6--   : bit 0,
#
my @A234691 = (119, 36, 93, 109, 46, 91, 123, 39, 127, 111);
my $A234691_aref = [0,1,2,3,4,5,6];

# " --0--   : bit 0,
# "5    1"  : bits 1+2,
#   --6--   
# "4    2"  : bit 5,
# " --3--   : bit 0,
#
my @A234692 = (63, 6, 91, 79, 102, 109, 125, 39, 127, 111, 47, 60, 57, 94, 121, 113);
my $A234692_aref = [0,5,1,6,4,2,3];


sub show {
  my ($bits, $aref) = @_;
  $aref //= [0,1,2,3,4,5,6];
  #  ---
  # |   |
  #  ---
  # |   |
  #  ---

  print " ",($bits & (1<<$aref->[0]) ? '---' : '   '), "\n";
  print $bits & (1<<$aref->[1]) ? '|' : ' ', "   ",
    $bits & (1<<$aref->[2]) ? '|' : ' ', "\n";
  print ".",($bits & (1<<$aref->[3]) ? '---' : '   '), ".\n";
  print $bits & (1<<$aref->[4]) ? '|' : ' ', "   ",
    $bits & (1<<$aref->[5]) ? '|' : ' ', "\n";
  print " ",($bits & (1<<$aref->[6]) ? '---' : '   '), "\n";
    
}

{
  print "\nA234691\n";
  # $A234691[5] = 0b1011011;
  # $A234691[5] = 0b1101011;
  $A234691[5] = 107;
  print "cf ",0b1101011,"\n";
  my $aref = $A234691_aref;
  foreach my $digit (0 .. 9) {
    my $bits = $A234691[$digit];
    printf "%d  %d  %07b\n", $digit, $bits, $bits;
    show($bits, $aref);
  }
}
{
  print "\nA234692\n";
  $A234692[10] = 119;
  $A234692[11] = 124;
  my $aref = $A234692_aref;
  foreach my $digit (0 .. 15) {
    $digit <= $#A234692 or die;
    my $bits = $A234692[$digit];
    printf "%X  %d  %07b\n", $digit, $bits, $bits;
    show($bits, $aref);
  }
}

sub permute {
  my ($bits) = @_;
  my $ret = 0;
  foreach my $i (0 .. 6) {
    if ($bits & (1<<$i)) {
      $ret += 1<<$A234692_aref->[$i];
    }
  }
  return $ret;
}
{
  print join(' ',@A234691),"\n";
  print join(' ',map {permute($_)} @A234691),"\n";
  print join(' ',@A234692),"\n";
}
exit 0;

# A334369_samples = [0, 1, 7, 1, 2, 1, 3, 1, 4, 5, 5, 6, 1, 7, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 3, 4, 5, 7, 9]

# A234692(n) = [63,6,91,79,102,109,125,39,127,111][n+1];
# [j | i<-[0..9];j<-[0..9], bitnegimply(A234692(j),A234692(i))==0]

# [j | i<-[0..9];j<-[0..9], bitnegimply(A234692(j),A234692(i))==0] == \
# A334369_samples

# what are subsets of i
# A234692(j) bits of j AND NOT A234692(i)
#   must not have bits in j not in i,  so j subset of i
# [i | i<-[0..9];j<-[0..9], bitnegimply(A234692(j),A234692(i))==0]
