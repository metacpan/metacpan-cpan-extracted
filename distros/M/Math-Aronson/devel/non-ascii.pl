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

use strict;
use warnings;
use Lingua::Any::Numbers;

{ local $,=' ';
  print Lingua::Any::Numbers::available(),"\n";
}

foreach my $lang (Lingua::Any::Numbers::available()) {
  foreach my $n (1 .. 500) {
    my $str = Lingua::Any::Numbers::to_ordinal($n,$lang);
    #     if ($str =~ /[^\0-\377]/) {
    #       say "$lang $n  $str";
    #     }
    if ($str =~ /([^[:ascii:]])/) {
      my $char = $1;
      my $ord = sprintf "%#X", ord($char);
      my $wide = (utf8::is_utf8($str) ? "wide " : "bytes");
      print "$lang $n $wide $ord   $str\n";
      last;
    }
  }
}
