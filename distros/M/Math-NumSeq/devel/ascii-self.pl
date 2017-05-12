#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

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
use List::Util 'min','max';

{
  require Math::NumSeq::AsciiSelf;
  foreach my $radix (2 .. 35) {
    my $seq = Math::NumSeq::AsciiSelf->new (radix => $radix);
    my $min = 999;
    my $max = 0;
    foreach (1 .. 100000) {
      my ($i,$value) = $seq->next;
      $min = min($min,$value);
      $max = max($max,$value);
    }
    my $defmax = $radix + ($radix <= 10 ? 47 : 65-10);
    my $minxx = ($min != 48 ? '**' : '');
    my $maxxx = ($max != $defmax ? '**' : '');
    print "$radix  $min$minxx $max$maxxx\n";
  }
  exit 0;
}

{
  require Math::NumSeq::AsciiSelf;
  foreach my $radix (2 .. 35) {
    my $seq = Math::NumSeq::AsciiSelf->new (radix => $radix);
    print "$radix: ";
    foreach (1 .. 20) {
      my ($i,$value) = $seq->next;
      print "$value,";
    }
    print "\n";
  }
  exit 0;
}

{
  require Math::NumSeq::AsciiSelf;
  require Math::BaseCnv;
  foreach my $radix (2 .. 35) {
    print "$radix\n";
    foreach my $digit (0 .. $radix-1) {
      my $ascii = Math::NumSeq::AsciiSelf::_digit_to_ascii($digit);
      my $base = Math::BaseCnv::cnv($ascii,10,$radix);
      print "  $base\n";
    }
    print "\n";
  }
  exit 0;
}

{
  require Math::NumSeq::AsciiSelf;
  require Math::BaseCnv;
  foreach my $radix (2 .. 64) {
    print "$radix   ";
    foreach my $i (48 .. 47+$radix) {
      my @ascii = Math::NumSeq::AsciiSelf::_radix_ascii($radix,$i);
      if ($ascii[0] == $i) {
        my $base = Math::BaseCnv::cnv($i,10,$radix);
        print join('_',@ascii), "  [$base], ";
      }
    }
    print "\n";
  }
  exit 0;
}

{
  require Math::NumSeq::AsciiSelf;
  foreach my $radix (2 .. 40) {
    my $seq = Math::NumSeq::AsciiSelf->new (radix => $radix);
    print "$radix   ",join(',',@{$seq->{'pending'}}),"\n";
  }
  exit 0;
}

