#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Math-Aronson.
#
# Math-Aronson is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Aronson is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Aronson.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Encode;
use Unicode::Normalize 'normalize';

use Smart::Comments;

{
  local $PerlIO::encoding::fallback = Encode::PERLQQ; # \x{1234} style
  binmode(\*STDOUT, ':locale') or die;
}

{
  my $from = '';
  my $to = '';
  foreach my $i (0x80 .. 0xFF) {
    my $str = chr($i);
    $str = Encode::decode ('latin-1', $str);

    # perl 5.10 thinks all non-ascii is alpha, or some such
    next unless $str =~ /[[:alpha:]]/;

    my $nfd = normalize('D',$str);
    ### $str
    ### $nfd

    if ($nfd =~ /^([[:ascii:]])/) {
      $from .= sprintf '\\%03o', $i;
      $to   .= $1;
    }
  }
  print "tr/$from/$to/\n";
  exit 0;
}

{
  require Unicode::CharName;
  my $count = 0;
  foreach my $i (0x80 .. 0xD7FF) {
    my $str = chr($i);
    my $nfd = normalize('D',$str);
    next if length($nfd) < 2;
    my $c = substr($nfd,0,1);
    next unless $c =~ /[[:ascii:]]/;
    next unless $c =~ /[[:alnum:]]/;
    my $name = Unicode::CharName::uname($i);
    printf "0x%04X  %s  %s\n", $i, $nfd, $name;
    $count++;
  }
  print "$count total\n";
  exit 0;
}


