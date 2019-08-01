#!/usr/bin/perl -w

# Copyright 2012, 2019 Kevin Ryde

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
plan tests => 30;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::ErdosSelfridgeClass;


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
# A005113, A056637 - first prime in n+, n-

foreach my $elem ([ 'A005113', '+' ],
                  [ 'A056637', '-' ]) {
  my ($anum, $p_or_m) = @$elem;
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $bvalues_count = scalar(@$bvalues);
    my $limit = 100000;
    if ($bvalues->[-1] > $limit) {
      while (@$bvalues && $bvalues->[-1] > $limit) {
        pop @$bvalues;
      }
    }
    MyTestHelpers::diag ("$anum has $bvalues_count values, shorten to ", scalar(@$bvalues));

    my $seq  = Math::NumSeq::ErdosSelfridgeClass->new
      (p_or_m => $p_or_m);
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      # if ($value > $#got) {
      #   print "$value\n";;
      # }
      if ($value > 0) {
        $got[$value-1] ||= $i;
      }
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
        1, "$anum -- first prime in class n$p_or_m");
}


#------------------------------------------------------------------------------
# A178382 - primes in k+ and k- for some k

{
  my $anum = 'A178382';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    MyTestHelpers::diag ("$anum has ",scalar(@$bvalues)," values");

    my $plus  = Math::NumSeq::ErdosSelfridgeClass->new (p_or_m=>'+');
    my $minus  = Math::NumSeq::ErdosSelfridgeClass->new (p_or_m=>'-');
    for (my $i = 2; @got < @$bvalues; $i++) {
      my $plus_class = $plus->ith($i);
      my $minus_class = $minus->ith($i);
      if ($plus_class != 0 && $plus_class == $minus_class) {
        push @got, $i;
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- primes in both class k+ and k- for some k");
}

#------------------------------------------------------------------------------
# A101253 - nth prime of class n+

{
  my $anum = 'A101253';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my $bvalues_count = scalar(@$bvalues);
  my $limit = 100000;
  if ($bvalues->[-1] > $limit) {
    while (@$bvalues && $bvalues->[-1] > $limit) {
      pop @$bvalues;
    }
  }
  MyTestHelpers::diag ("$anum has $bvalues_count values, shorten to ", scalar(@$bvalues));

  my @got;
  if ($bvalues) {
    MyTestHelpers::diag ("$anum has ",scalar(@$bvalues)," values");

    my $seq  = Math::NumSeq::ErdosSelfridgeClass->new;
    my @count;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if ($value > 0) {
        $count[$value]++;
        if ($count[$value] == $value) {
          $got[$value-1] = $i;
        }
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- nth prime of class n+");
}

#------------------------------------------------------------------------------
# A098661 - cumulative nth prime of class n+

{
  my $anum = 'A098661';
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $bvalues_count = scalar(@$bvalues);
    my $limit = 100_000;
    if ($bvalues->[-1] > $limit) {
      while (@$bvalues && $bvalues->[-1] > $limit) {
        pop @$bvalues;
      }
    }
    MyTestHelpers::diag ("$anum has $bvalues_count values, shorten to ", scalar(@$bvalues));

    my $seq  = Math::NumSeq::ErdosSelfridgeClass->new;
    my @count;
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if ($value > 0) {
        $count[$value]++;
        if ($count[$value] == $value) {
          $got[$value-1] = $i;
        }
      }
    }
    foreach my $i (1 .. $#got) {
      $got[$i] += $got[$i-1];
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..6]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..6]));
    }
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- cumulative nth of class n+");
}

#------------------------------------------------------------------------------
# primes in classes

foreach my $elem ([ 'A005109', 1, '-' ], # Pierpont
                  [ 'A005110', 2, '-' ],
                  [ 'A005111', 3, '-' ],
                  [ 'A005112', 4, '-' ],
                  [ 'A081424', 5, '-' ],
                  [ 'A081425', 6, '-' ],
                  [ 'A081640', 12, '-' ],
                  [ 'A129248', 14, '-' ],
                  [ 'A129249', 15, '-' ],
                  [ 'A129250', 16, '-' ],

                  [ 'A005105', 1, '+' ],
                  [ 'A005106', 2, '+' ],
                  [ 'A005107', 3, '+' ],
                  [ 'A005108', 4, '+' ],
                  [ 'A081633', 5, '+' ],
                  [ 'A081634', 6, '+' ],
                  [ 'A081635', 7, '+' ],
                  [ 'A081636', 8, '+' ],
                  [ 'A081637', 9, '+' ],
                  [ 'A081638', 10, '+' ],
                  [ 'A081639', 11, '+' ],
                  [ 'A084071', 12, '+' ],
                  [ 'A090468', 13, '+' ],
                  [ 'A129474', 14, '+' ],
                  [ 'A129475', 15, '+' ],
                 ) {
  my ($anum, $want_class, $p_or_m) = @$elem;
  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $bvalues_count = scalar(@$bvalues);
    my $limit = 100_000;
    if ($bvalues->[-1] > $limit) {
      while (@$bvalues && $bvalues->[-1] > $limit) {
        pop @$bvalues;
      }
    }
    MyTestHelpers::diag ("$anum has $bvalues_count values, shorten to ", scalar(@$bvalues));

    my $seq  = Math::NumSeq::ErdosSelfridgeClass->new
      (p_or_m => $p_or_m);
    while (@got < @$bvalues) {
      my ($i, $value) = $seq->next;
      if ($value == $want_class) {
        push @got, $i;
      }
    }
    if (! numeq_array(\@got, $bvalues)) {
      MyTestHelpers::diag ("bvalues: ",join(',',@{$bvalues}[0..20]));
      MyTestHelpers::diag ("got:     ",join(',',@got[0..20]));
    }
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  skip (! $bvalues,
        numeq_array(\@got, $bvalues),
        1, "$anum -- primes in class $want_class$p_or_m");
}

#------------------------------------------------------------------------------
exit 0;
