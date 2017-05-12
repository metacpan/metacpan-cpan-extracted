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
use POSIX 'ceil';
use Test;
plan tests => 9;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::MephistoWaltz;

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
# A134391 - runs 0 to 3^k-1

{
  my $anum = 'A134391';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum,
                                                      max_value => 10000);
  my $diff;
  if ($bvalues) {
    my @got;
    my $seq = Math::NumSeq::MephistoWaltz->new;
    my $str = '';
    my $target = 1;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if ($i == $target) {
        $seq->rewind;
        $target *= 3;
      } else {
        push @got, $value;
      }
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..30]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..30]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum");
}

#------------------------------------------------------------------------------
# A064991 - replications as decimal bignums

{
  my $anum = 'A064991';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum,
                                                      max_value => 10000);
  my $diff;
  if ($bvalues) {
    my @got;
    my $seq = Math::NumSeq::MephistoWaltz->new;
    require Math::BigInt;
    my $word = Math::BigInt->new(0);
    my $target = 1;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if ($i == $target) {
        push @got, $word;
        $target *= 3;
      }
      $word = 2*$word + $value;
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..30]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..30]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum");
}

#------------------------------------------------------------------------------
# A007051 - (3^n + 1)/2 zeros to i<3^n

{
  my $anum = 'A007051';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum,
                                                      max_value => 10000);
  my $diff;
  if ($bvalues) {
    my @got;
    my $seq = Math::NumSeq::MephistoWaltz->new;
    my $count = 0;
    my $target = 1;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if ($i == $target) {
        push @got, $count;
        $target *= 3;
      }
      if ($value == 0) {
        $count++;
      }
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..30]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..30]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum");
}

#------------------------------------------------------------------------------
# A003462 - (3^n - 1)/2 ones to i<3^n

{
  my $anum = 'A003462';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum,
                                                      max_value => 10000);
  my $diff;
  if ($bvalues) {
    my @got;
    my $seq = Math::NumSeq::MephistoWaltz->new;
    my $count = 0;
    my $target = 1;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if ($i == $target) {
        push @got, $count;
        $target *= 3;
      }
      if ($value == 1) {
        $count++;
      }
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..9]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..9]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum");
}


#------------------------------------------------------------------------------
# A156595 - xor diffs

{
  my $anum = 'A156595';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  {
    my $diff;
    if ($bvalues) {
my $seq = Math::NumSeq::MephistoWaltz->new;

      my @got;
      my ($i, $prev) = $seq->next;
      while (@got < @$bvalues) {
        my ($i, $value) = $seq->next;
        push @got, $prev ^ $value;
        $prev = $value;
      }
      $diff = diff_nums(\@got, $bvalues);
      if ($diff) {
        MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..30]));
        MyTestHelpers::diag ("got:     ",join(',',@got[0..30]));
      }
    }
    skip (! $bvalues,
          $diff, undef,
          "$anum");
  }

  sub ternary2s {
    my ($n) = @_;
    my $ret = 0;
    while ($n) {
      my $rem = $n % 3;
      $n = ($n-$rem)/3;
      if ($rem == 2) {
        $ret ^= 1;
      }
    }
    return $ret;
  }
  sub calc_A156595 {
    my ($n) = @_;

    # return ternary2s($n) ^ ternary2s($n+1);
    # N+1 changes 2s once for each trailing 2 and then once more if 1-trit
    # above that.
    # ...1222..22 + 1 = ...2000..00

    my $ret = 0;
    for (;;) {
      my $rem = $n % 3;
      $n = ($n-$rem)/3;
      if ($rem == 0) {
        last;
      }
      if ($rem == 1) {
        $ret ^= 1;
        last;
      }
      if ($rem == 2) {
        $ret ^= 1;
      }
    }
    return $ret;
  }
  {
    my $diff;
    if ($bvalues) {
      my @got;
      for (my $n = 0; @got < @$bvalues; $n++) {
        push @got, calc_A156595($n);
      }
      $diff = diff_nums(\@got, $bvalues);
      if ($diff) {
        MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..30]));
        MyTestHelpers::diag ("got:     ",join(',',@got[0..30]));
      }
    }
    skip (! $bvalues,
          $diff, undef,
          "$anum");
  }
}

#------------------------------------------------------------------------------
# A189658 - positions of 0s, but n+1 so counting from value=1 for the first

{
  my $anum = 'A189658';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my $diff;
  if ($bvalues) {
    my @got;
    my $seq = Math::NumSeq::MephistoWaltz->new;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if ($value == 0) {
        push @got, $i + 1;
      }
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..30]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..30]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum -- positions of 0s");
}

#------------------------------------------------------------------------------
# A189659 - positions of 1s, but n+1 so counting from value=1 for the first

{
  my $anum = 'A189659';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my $diff;
  if ($bvalues) {
    my @got;
    my $seq = Math::NumSeq::MephistoWaltz->new;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if ($value == 1) {
        push @got, $i + 1;
      }
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..30]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..30]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum");
}

#------------------------------------------------------------------------------
# A189660 - cumulative

{
  my $anum = 'A189660';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my $diff;
  if ($bvalues) {
    my @got;
    my $seq = Math::NumSeq::MephistoWaltz->new;
    my $total = 0;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      $total += $value;
      push @got, $total;
    }
    $diff = diff_nums(\@got, $bvalues);
    if ($diff) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..30]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..30]));
    }
  }
  skip (! $bvalues,
        $diff, undef,
        "$anum");
}

#------------------------------------------------------------------------------
exit 0;
