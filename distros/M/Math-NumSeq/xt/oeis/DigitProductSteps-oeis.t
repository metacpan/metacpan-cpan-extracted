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
use List::Util 'max','min';

use Test;
plan tests => 12;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::DigitProductSteps;

# uncomment this to run the ### lines
#use Smart::Comments '###';


sub diff_nums {
  my ($gotaref, $wantaref) = @_;
  for (my $i = 0; $i < @$gotaref; $i++) {
    if ($i > @$wantaref) {
      return "want ends prematurely pos=$i";
    }
    my $got = $gotaref->[$i];
    my $want = $wantaref->[$i];
    if (! defined $got && ! defined $want) {
      next;
    }
    if (! defined $got || ! defined $want) {
      return "different pos=$i got=".(defined $got ? $got : '[undef]')
        ." want=".(defined $want ? $want : '[undef]');
    }
    $got =~ /^[0-9.-]+$/
      or return "not a number pos=$i got='$got'";
    $want =~ /^[0-9.-]+$/
      or return "not a number pos=$i want='$want'";
    if ($got != $want) {
      return "different pos=$i numbers got=$got want=$want";
    }
  }
  return undef;
}



#------------------------------------------------------------------------------
# A034048 etc - values with digital root 0,1,...,9

{
  foreach my $elem ([0,'A034048'],
                    [1,'A002275'], # repunits
                    [2,'A034049'],
                    [3,'A034050'],
                    [4,'A034051'],
                    [5,'A034052'],
                    [6,'A034053'],
                    [7,'A034054'],
                    [8,'A034055'],
                    [9,'A034056']) {
    my ($root,$anum) = @$elem;
    my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum,
                                                        max_value => 100_000);
    my $diff;
    if (! $bvalues) {
      MyTestHelpers::diag ("$anum not available");
    } else {

      if ($anum eq 'A002275' && $bvalues->[0] == 0) {
        # A002275 reckons 0 as a repunit, don't want that here
        shift @$bvalues;
      }

      my $seq = Math::NumSeq::DigitProductSteps->new (values_type => 'root');
      my @got;
      while (@got < @$bvalues) {
        my ($i, $value) = $seq->next;
        if ($value == $root) {
          ### $value
          push @got, $i;
        }
      }
      $diff = diff_nums(\@got, $bvalues);
      if ($diff) {
        MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..$#$bvalues]));
        MyTestHelpers::diag ("got:     ",join(',',@got[0..$#got]));
      }
      $root++;
    }
    skip (! $bvalues,
          $diff, undef,
          "$anum - digital root $root");
  }
}

#------------------------------------------------------------------------------
# A014553 - maximum persistence for n digits
# cf A035927 counting 10-sets
#    A046148 how many with maximal persistence
#    A046149 smallest of those
#    A046150 biggest of those

{
  my $anum = 'A014553';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum,
                                                      max_count => 4);
  my $diff;
  if (! $bvalues) {
    MyTestHelpers::diag ("$anum not available");
  } else {
    my $seq = Math::NumSeq::DigitProductSteps->new;
    my @got = (1);  # for some reason 1 to 9 reckoned as 1 iteration
    my $len = 1;
    while (@got < @$bvalues) {
      my $max = 0;
      foreach my $i (10**$len .. 10**($len+1)-1) {
        $max = max ($max, $seq->ith($i));
      }
      push @got, $max;
      $len++;
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..$#$bvalues]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..$#got]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum");
}


#------------------------------------------------------------------------------
# A003001 - first of persistence n

{
  my $anum = 'A003001';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum,
                                                      max_value => 1_000_000);
  my $diff;
  if (! $bvalues) {
    MyTestHelpers::diag ("$anum not available");
  } else {
    my $seq = Math::NumSeq::DigitProductSteps->new;
    my @got;
    my $target = 0;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if ($value == $target) {
        push @got, $i;
        $target++;
      }
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..$#$bvalues]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..$#got]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum - first of persistence n");
}



#------------------------------------------------------------------------------
exit 0;
