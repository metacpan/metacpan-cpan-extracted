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
plan tests => 5;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::SternDiatomic;
use Math::NumSeq::Fibonacci;

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
# A049455 - repeat runs diatomic 0 to 2^k

{
  my $anum = 'A049455';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    @$bvalues = grep {$_<100000} @$bvalues; # shorten
    MyTestHelpers::diag ("$anum has ",scalar(@$bvalues)," values");

    my $seq = Math::NumSeq::SternDiatomic->new;
  OUTER: for (my $exp = 0; ; $exp++) {
      foreach my $i (0 .. 2**$exp) {
        push @got, $seq->ith($i);
        last OUTER if @got >= @$bvalues;
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..30]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..30]));
    }
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum");
}

#------------------------------------------------------------------------------
# A049456 - extra 1 at end of each row

{
  my $anum = 'A049456';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    @$bvalues = grep {$_<100000} @$bvalues; # shorten
    MyTestHelpers::diag ("$anum has ",scalar(@$bvalues)," values");

    my $seq = Math::NumSeq::SternDiatomic->new;
    $seq->next;
    for (;;) {
      my ($i,$value) = $seq->next;
      push @got, $value;
      last if @got >= @$bvalues;
      if ($i > 1 && is_pow2($i)) {
        push @got, 1;
        last if @got >= @$bvalues;
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..30]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..30]));
    }
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum");
}

sub is_pow2 {
  my ($n) = @_;
  return ($n & ($n-1)) == 0;
}

#------------------------------------------------------------------------------
# A126606 - starting 0,2 so double of Stern diatomic

{
  my $anum = 'A126606';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    @$bvalues = grep {$_<100000} @$bvalues; # shorten
    MyTestHelpers::diag ("$anum has ",scalar(@$bvalues)," values");

    my $seq = Math::NumSeq::SternDiatomic->new;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      push @got, $value*2;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..5]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..5]));
    }
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum");
}

#------------------------------------------------------------------------------
# A061547 - position of Fibonacci F[n],F[n+1] in Stern diatomic
#
# Stern: 0,1,1,2,1,3,2,3,1,4,3,5,2,5,3,4,1,5,4,7,3,
#            ^       ^       ^
#           i=2     i=6     i=10

{
  my $anum = 'A061547';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    @$bvalues = grep {$_<100000} @$bvalues; # shorten
    MyTestHelpers::diag ("$anum has ",scalar(@$bvalues)," values");

    my $stern = Math::NumSeq::SternDiatomic->new;
    my $fib = Math::NumSeq::Fibonacci->new;
    my (undef, $fprev) = $fib->next;
    my (undef, $fvalue) = $fib->next;
    my (undef, $sprev) = $stern->next;
    while (@got < @$bvalues) {
      my ($i, $svalue) = $stern->next;
      ### at: "stern $sprev,$svalue seeking $fprev,$fvalue"
      if ($sprev == $fprev
          && $svalue == $fvalue) {
        ### found: "$fvalue,$fprev at i=$i"
        push @got, $i - 1;
        $fprev = $fvalue;
        (undef, $fvalue) = $fib->next;
      }
      $sprev = $svalue;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..5]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..5]));
    }
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- positions of Fibonacci F[n],F[n+1]");
}


#------------------------------------------------------------------------------
# A086893 - position of Fibonacci F[n+1],F[n] in Stern diatomic
#
# Stern: 0,1,1,2,1,3,2,3,1,4,3,5,2,5,3,4,1,5,4,7,3,
#              ^   ^               ^
#             i=3 i=5             i=13

{
  my $anum = 'A086893';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    @$bvalues = grep {$_<100000} @$bvalues; # shorten
    MyTestHelpers::diag ("$anum has ",scalar(@$bvalues)," values");

    my $stern = Math::NumSeq::SternDiatomic->new;
    my $fib = Math::NumSeq::Fibonacci->new;
    $fib->next;    # skip 0
    my (undef, $fprev) = $fib->next;
    my (undef, $fvalue) = $fib->next;
    my (undef, $sprev) = $stern->next;
    while (@got < @$bvalues) {
      my ($i, $svalue) = $stern->next;
      ### at: "stern $sprev,$svalue seeking $fprev,$fvalue"
      if ($sprev == $fvalue
          && $svalue == $fprev) {
        ### found: "$fvalue,$fprev at i=$i"
        push @got, $i - 1;
        $fprev = $fvalue;
        (undef, $fvalue) = $fib->next;
      }
      $sprev = $svalue;
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..5]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..5]));
    }
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- positions of Fibonacci F[n+1],F[n]");
}



#------------------------------------------------------------------------------
exit 0;
