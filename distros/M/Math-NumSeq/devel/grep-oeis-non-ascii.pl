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

require 5;
use strict;
use Text::Tabs;

{
  # ampersands in description()
  require Math::NumSeq::OEIS::Catalogue;
  my $anum = 'A000000';
  for (;;) {
    $anum = Math::NumSeq::OEIS::Catalogue->anum_after($anum) // last;
    my $description = Math::NumSeq::OEIS->new(anum=>$anum)->description;
    if ($description =~ /&/) {
      print "$anum: $description\n";
    }
  }
  exit 0;
}

{
  # ampersands
  foreach my $filename (<~/OEIS/*.internal>, <~/OEIS/*.internal.html>) {
    open FH, '<', $filename or next;
    my $contents = do { local $/; <FH> }; # slurp
    close FH or die;

    $contents =~ s{(.*)}{my $line = $1;
                         ($line =~ /^%N/ ? $line : '')}eg;

    my $count = 0;
    while ($contents =~ /(&+)/g) {
      my $char = sprintf '0x%X', ord($1);
      my ($linenum, $column) = pos_to_line_and_column($contents,pos($contents)-1);
      print "$filename:$linenum:$column: $char\n";
      last if ++$count > 5;
    }
  }
  exit 0;
}

{
  # non-ascii
  foreach my $filename (<~/OEIS/*.internal>, <~/OEIS/*.internal.html>) {
    open FH, '<', $filename or next;
    my $contents = do { local $/; <FH> }; # slurp
    close FH or die;

    $contents =~ s{(.*)}{my $line = $1;
                         ($line =~ /^%N/ ? $line : '')}eg;

    my $count = 0;
    while ($contents =~ /([^[:ascii:]]+)/g) {
      my $char = sprintf '0x%X', ord($1);
      my ($linenum, $column) = pos_to_line_and_column($contents,pos($contents)-1);
      print "$filename:$linenum:$column: $char\n";
      last if ++$count > 5;
    }
  }
}

sub pos_to_line_and_column {
  my ($str, $pos) = @_;
  $str = substr ($str, 0, $pos);
  my $nlpos = rindex ($str, "\n");
  my $lastline = substr ($str, $nlpos+1);
  $lastline = Text::Tabs::expand ($lastline);
  my $colnum = 1 + length ($lastline);
  my $linenum = 1 + scalar($str =~ tr/\n//);
  return ($linenum, $colnum);
}
