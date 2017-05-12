#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Math-Aronson.
#
# Math-Aronson is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Aronson is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Aronson.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use Test;
plan tests => 11;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;

use Math::NumSeq::Aronson;

# uncomment this to run the ### lines
#use Devel::Comments '###';


sub diff_nums {
  my ($gotaref, $wantaref) = @_;
  for (my $i = 0; $i < @$gotaref; $i++) {
    if ($i > @$wantaref) {
      return "want ends prematurely i=$i";
    }
    my $got = $gotaref->[$i];
    my $want = $wantaref->[$i];
    if (! defined $got && ! defined $want) {
      next;
    }
    if (! defined $got || ! defined $want) {
      return "different i=$i got=".(defined $got ? $got : '[undef]')
        ." want=".(defined $want ? $want : '[undef]');
    }
    $got =~ /^[0-9.-]+$/
      or return "not a number i=$i got='$got'";
    $want =~ /^[0-9.-]+$/
      or return "not a number i=$i want='$want'";
    if ($got != $want) {
      return "different i=$i numbers got=$got want=$want";
    }
  }
  return undef;
}

sub numeq_array {
  my ($a1, $a2) = @_;
  if (! ref $a1 || ! ref $a2) {
    return 0;
  }
  while (@$a1 && @$a2) {
    if ($a1->[0] ne $a2->[0]) {
      return 0;
    }
    shift @$a1;
    shift @$a2;
  }
  return (@$a1 == @$a2);
}

#------------------------------------------------------------------------------
# A005224 -- English T, without conjunctions

{
  my $anum = 'A005224';
  my $numseq  = Math::NumSeq::Aronson->new (conjunctions => 0);
  ok ($numseq->oeis_anum, $anum, "$anum oeis_anum()");

  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    foreach my $n (1 .. @$bvalues) {
      my ($i, $value) = $numseq->next;
      if (! defined $value) {
        last;
      }
      push @got, $value;
    }
    MyTestHelpers::diag ("$anum has $#$bvalues values");
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  ### bvalues: @$bvalues
  ### @got
  my $diff = $bvalues && diff_nums(\@got, $bvalues);
  skip (! $bvalues,
        $diff,
        undef, "$anum -- English T, without conjunctions");
  if (defined $diff) {
    MyTestHelpers::diag ("got     ". join(',', map {defined() ? $_ : 'undef'} @got));
    MyTestHelpers::diag ("bvalues ". join(',', map {defined() ? $_ : 'undef'} @$bvalues));
  }
}

#------------------------------------------------------------------------------
# A055508 -- English H, without conjunctions

{
  my $anum = 'A055508';
  my $numseq  = Math::NumSeq::Aronson->new (letter => 'H',
                                            conjunctions => 0);
  ok ($numseq->oeis_anum, $anum, "$anum oeis_anum()");

  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    foreach my $n (1 .. @$bvalues) {
      my ($i, $value) = $numseq->next;
      if (! defined $value) {
        last;
      }
      push @got, $value;
    }
    MyTestHelpers::diag ("$anum has $#$bvalues values");
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  ### bvalues: @$bvalues
  ### @got
  my $diff = $bvalues && diff_nums(\@got, $bvalues);
  skip (! $bvalues,
        $diff,
        undef, "$anum -- English H, without conjunctions");
  if (defined $diff) {
    MyTestHelpers::diag ("got     ". join(',', map {defined() ? $_ : 'undef'} @got));
    MyTestHelpers::diag ("bvalues ". join(',', map {defined() ? $_ : 'undef'} @$bvalues));
  }
}

#------------------------------------------------------------------------------
# A049525 -- English I, without conjunctions

{
  my $anum = 'A049525';
  my $numseq  = Math::NumSeq::Aronson->new (letter => 'I',
                                            conjunctions => 0);
  ok ($numseq->oeis_anum, $anum, "$anum oeis_anum()");

  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    foreach my $n (1 .. @$bvalues) {
      my ($i, $value) = $numseq->next;
      if (! defined $value) {
        last;
      }
      push @got, $value;
    }
    MyTestHelpers::diag ("$anum has $#$bvalues values");
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  ### bvalues: @$bvalues
  ### @got
  my $diff = $bvalues && diff_nums(\@got, $bvalues);
  skip (! $bvalues,
        $diff,
        undef, "$anum -- English I, without conjunctions");
  if (defined $diff) {
    MyTestHelpers::diag ("got     ". join(',', map {defined() ? $_ : 'undef'} @got));
    MyTestHelpers::diag ("bvalues ". join(',', map {defined() ? $_ : 'undef'} @$bvalues));
  }
}

#------------------------------------------------------------------------------
# A081023 -- English T, lying

{
  my $anum = 'A081023';
  my $numseq  = Math::NumSeq::Aronson->new (lying => 1,
                                            # not enough to tell if difference
                                             conjunctions => 0,
                                           );
  ok ($numseq->oeis_anum, $anum, "$anum oeis_anum()");

  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    foreach my $n (1 .. @$bvalues) {
      my ($i, $value) = $numseq->next;
      if (! defined $value) {
        last;
      }
      push @got, $value;
    }
    MyTestHelpers::diag ("$anum has $#$bvalues values");
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  ### bvalues: @$bvalues
  ### @got
  my $diff = $bvalues && diff_nums(\@got, $bvalues);
  skip (! $bvalues,
        $diff,
        undef, "$anum -- English T, lying");
  if (defined $diff) {
    MyTestHelpers::diag ("got     ". join(',', map {defined() ? $_ : 'undef'} @got));
    MyTestHelpers::diag ("bvalues ". join(',', map {defined() ? $_ : 'undef'} @$bvalues));
  }
}

#------------------------------------------------------------------------------
# A081024 -- English T, lying, complement

{
  my $anum = 'A081024';
  my $numseq  = Math::NumSeq::Aronson->new (lying => 1,
                                            # not enough to tell if difference
                                            conjunctions => 0,
                                           );

  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    my $value = 0;
    my $upto = 0;
    foreach my $n (1 .. @$bvalues) {
      while ($upto == $value) {
        (undef, $value) = $numseq->next;
        $upto++;
      }
      push @got, $upto;
      $upto++;
    }
    MyTestHelpers::diag ("$anum has $#$bvalues values");
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  ### bvalues: @$bvalues
  ### @got
  my $diff = $bvalues && diff_nums(\@got, $bvalues);
  skip (! $bvalues,
        $diff,
        undef, "$anum -- English T, lying, complement");
  if (defined $diff) {
    MyTestHelpers::diag ("got     ". join(',', map {defined() ? $_ : 'undef'} @got));
    MyTestHelpers::diag ("bvalues ". join(',', map {defined() ? $_ : 'undef'} @$bvalues));
  }
}


#------------------------------------------------------------------------------
# A080520 -- French

{
  my $anum = 'A080520';
  my $numseq  = Math::NumSeq::Aronson->new (lang => 'fr');
  ok ($numseq->oeis_anum, $anum, "$anum oeis_anum()");

  my ($bvalues, $lo, $filename) = MyOEIS::read_values($anum);
  my @got;
  if ($bvalues) {
    foreach my $n (1 .. @$bvalues) {
      my ($i, $value) = $numseq->next;
      if (! defined $value) {
        last;
      }
      push @got, $value;
    }
    MyTestHelpers::diag ("$anum has $#$bvalues values");
  } else {
    MyTestHelpers::diag ("$anum not available");
  }
  ### bvalues: @$bvalues
  ### @got
  my $diff = $bvalues && diff_nums(\@got, $bvalues);
  skip (! $bvalues,
        $diff,
        undef, "$anum -- French");
  if (defined $diff) {
    MyTestHelpers::diag ("got     ". join(',', map {defined() ? $_ : 'undef'} @got));
    MyTestHelpers::diag ("bvalues ". join(',', map {defined() ? $_ : 'undef'} @$bvalues));
  }
}

#------------------------------------------------------------------------------
exit 0;
