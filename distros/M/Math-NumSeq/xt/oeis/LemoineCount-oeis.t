#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
plan tests => 2;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::LemoineCount;

# uncomment this to run the ### lines
#use Smart::Comments '###';


sub numeq_array {
  my ($a1, $a2) = @_;
  if (! ref $a1 || ! ref $a2) {
    return 0;
  }
  my $i = 0;
  while ($i < @$a1 && $i < @$a2) {
    if ($a1->[$i] ne $a2->[$i]) {
      return 0;
    }
    $i++;
  }
  return (@$a1 == @$a2);
}



#------------------------------------------------------------------------------
# A194830 - odd record positions

{
  my $anum = 'A194830';

  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $bvalues_count = scalar(@$bvalues);
    my $limit = 60;
    if ($#$bvalues > $limit) { $#$bvalues = $limit; }
    MyTestHelpers::diag ("$anum has $bvalues_count values, shorten to ", scalar(@$bvalues));

    my $seq = Math::NumSeq::LemoineCount->new;
    my $record = 0;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if (($i&1) && $value > $record) {
        $record = $value;
        push @got, $i;
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..10]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..10]));
    }
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- odd record positions");
}


#------------------------------------------------------------------------------
# A194831 - odd record values

{
  my $anum = 'A194831';

  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $bvalues_count = scalar(@$bvalues);
    my $limit = 60;
    if ($#$bvalues > $limit) { $#$bvalues = $limit; }
    MyTestHelpers::diag ("$anum has $bvalues_count values, shorten to ", scalar(@$bvalues));

    my $seq = Math::NumSeq::LemoineCount->new;
    my $record = 0;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if (($i&1) && $value > $record) {
        $record = $value;
        push @got, $value;
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..10]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..10]));
    }
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- odd record counts");
}



#------------------------------------------------------------------------------
exit 0;
