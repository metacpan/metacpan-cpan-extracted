#!/usr/bin/perl -w

# Copyright 2012 Kevin Ryde

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


# Usage: perl cellular-rules.pl
#
# Print the patterns from the CellularRule paths with "*"s.
# Rules with the same output are listed together.
#
# Implementation:
#
# Points are plotted by looping $n until its $y coordinate is beyond the
# desired maximum rows.  @rows is an array of strings of length 2*size+1
# spaces each in which "*"s are applied to plot points.
#
# Another way to plot would be to loop over $x,$y for the desired rectangle
# and look at $n=$path->xy_to_n($x,$y) to see which cells have defined($n).
# Characters could be appended or join(map{}) to make an output $str in that
# case.  Going by $n should be fastest for sparse patterns, though
# CellularRule is not blindingly quick either way.
#
# See Cellular::Automata::Wolfram for the same but with more options and a
# graphics file output.
#

use 5.004;
use strict;
use Math::PlanePath::CellularRule;

my $numrows = 15;    # size of each printout

my %seen;
my $count = 0;
my $mirror_count = 0;
my $finite_count = 0;

my @strs;
my @rules_list;
my @mirror_of;

foreach my $rule (0 .. 255) {
  my $path = Math::PlanePath::CellularRule->new (rule => $rule);

  my @rows = (' ' x (2*$numrows+1)) x ($numrows+1);  # strings of spaces
  for (my $n = $path->n_start; ; $n++) {
    my ($x,$y) = $path->n_to_xy($n)
      or last; # some patterns are only finitely many N values
    last if $y > $numrows; # stop at $numrows+1 many rows

    substr($rows[$y], $x+$numrows, 1) = '*';
  }
  @rows = reverse @rows;  # print rows going up the page

  my $str = join("\n",@rows);   # string of all rows
  my $seen_rule = $seen{$str};  # possible previous rule giving this $str
  if (defined $seen_rule) {
    # $str is a repeat of an output already seen, note this $rule with that
    $rules_list[$seen_rule] .= ",$rule";
    next;
  }

  my $mirror_str = join("\n", map {scalar(reverse)} @rows);
  my $mirror_rule = $seen{$mirror_str};
  if (defined $mirror_rule) {
    $mirror_of[$mirror_rule] = " (mirror image is rule $rule)";
    $mirror_of[$rule] = " (mirror image of rule $mirror_rule)";
    $mirror_count++;
  }

  $strs[$rule] = $str;
  $rules_list[$rule] = $rule;
  $seen{$str} = $rule;
  $count++;

  if ($rows[0] =~ /^ *$/) {
    $finite_count++;
  }
}

foreach my $rule (0 .. 255) {
  my $str = $strs[$rule] || next;
  print "rule=$rules_list[$rule]", $mirror_of[$rule]||'', "\n";
  print "\n$strs[$rule]\n\n";
}

my $unmirrored_count = $count - $mirror_count;

print "Total $count different rule patterns\n";
print "$mirror_count are mirror images of another\n";
print "$finite_count stop after a few cells\n";
exit 0;
