#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde

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
plan tests => 9;

use lib 't','xt';
use MyTestHelpers;
MyTestHelpers::nowarnings();
use MyOEIS;


#------------------------------------------------------------------------------
# A137564 - keep leftmost copy of each distinct digit occurring

{
  my $x = !0;
  ok ($x eq '1', 1);
  ok ($x&&'abc', 'abc');
  my $y = !1;
  ok ($y eq '', 1);
}

# split and join not very string-like
# use List::Util 'uniq'; sub A137564 { join('',uniq(split //,$_[0])) }
# no sequence with sort(uniq())
#
sub A137564 {my($n)=@_; my @seen; $n =~ s{.}{!$seen[$&]++ && $&}eg; $n} # xxx

MyOEIS::compare_values
  (anum => 'A137564',
   func => sub {
     my ($count) = @_;
     return [map {A137564($_)} 0 .. $count-1];
   });

# A337864 - collapse contiguous blocks of digits to one of each
#
sub A337864 {my($n)=@_; $n =~ s/(.)\1+/$1/g; $n}
MyOEIS::compare_values
  (anum => 'A337864',   # old b-file of A137564
   func => sub {
     my ($count) = @_;
     return [map {A337864($_)} 0 .. $count-1];
   });

#------------------------------------------------------------------------------
# A051022 - 0 between digits (above each)

sub A051022 { my($n)=@_; $n =~ s/\B./0$&/g; $n }

MyOEIS::compare_values
  (anum => 'A051022',
   func => sub {
     my ($count) = @_;
     return [map {A051022($_)} 0 .. $count-1];
   });

#------------------------------------------------------------------------------
# A004185 - sort digits

# but might want to inherit bigint input
# +0 to strip high 0s
sub A004185 { join('', sort split //,$_[0]) + 0 }
ok(A004185(0), '0');
ok(A004185(100), '1');

MyOEIS::compare_values
  (anum => 'A004185',
   func => sub {
     my ($count) = @_;
     return [map {A004185($_)} 0 .. $count-1];
   });


#------------------------------------------------------------------------------
