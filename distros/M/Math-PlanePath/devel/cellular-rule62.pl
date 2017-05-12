#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

use strict;

my $rule = 57;
my @table = map {($rule & (1<<$_)) ? 1 : 0} 0 .. 7;
print join(',',@table),"\n";

my @mirror = (map { ($_&4?1:0)+($_&2?2:0)+($_&1?4:0) } 0 .. 7);

print "join table ",oct('0b'. join('', map{$table[$_]} reverse 0 .. 7)),"\n";
print "join table ",oct('0b'. join('', map{$table[$mirror[$_]]} reverse 0 .. 7)),"\n";

# uncomment this to run the ### lines
#use Devel::Comments;

my @a = ([(0)x50, 1, (0)x50]);
print_line(0);

foreach my $level (1..20) {
  my $prev = $a[$level-1];
  ### @a
  foreach my $i (1 .. $#$prev) {
    my $p = 4*($prev->[$i-1]||0) + 2*($prev->[$i]||0) + ($prev->[$i+1]||0);
    $a[$level]->[$i] = $table[$p];
  }
  print_line($level);
}

sub print_line {
  my ($level) = @_;
  foreach my $i (0 .. $#{$a[$level]}) {
    my $c = $a[$level]->[$i];
    if ($table[0]) {
      print $c  ? ' ' : "*";
    } else {
      print $c  ? '*' : " ";
    }
  }
  print "\n";
}
exit 0;
