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

use 5.010;
use strict;
use warnings;
use Math::NumSeq::OEIS;
use Math::NumSeq::OEIS::Catalogue::Plugin::ZZ_Files;

# uncomment this to run the ### lines
use Smart::Comments;

open my $fh, '>', "$ENV{HOME}/OEIS/oeis-grep.txt" or die;
my $count = 0;
my $aref = Math::NumSeq::OEIS::Catalogue::Plugin::ZZ_Files->info_arrayref;
my @infos = @$aref;
@infos = sort {$a->{'anum'} cmp $b->{'anum'}} @infos;
foreach my $info (@infos) {
  my $anum = $info->{'anum'};
  my $seq = Math::NumSeq::OEIS::File->new (anum => $anum);

  my @values;
  my ($i, $value) = $seq->next
    or die "$anum no values";
  print $fh "$anum start=$i: $value";
  push @values, $value;
  my $any_negative = ($value < 0);

  for (1 .. 100) {
    my ($i, $value) = $seq->next or last;
    if (length($value) > 20) {
      last;
    }
    print $fh ",$value";
    push @values, $value;
    $any_negative ||= ($value < 0);
  }
  print $fh "\n";

  if ($any_negative) {
    print $fh "$anum start=$i abs: ",join(',',map{abs}@values),"\n";
  }
  $count++;
}
print "total $count sequences\n";
