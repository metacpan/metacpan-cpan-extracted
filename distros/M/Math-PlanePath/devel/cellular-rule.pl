#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

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
use Math::PlanePath::CellularRule;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # A169707 rule 750
  my %grid;
  my $width = 40;
  my $height = 40;
  $grid{0,0} = 1;
  foreach my $level (0 .. 40) {

    print "level $level\n";
    foreach my $y (reverse -$height .. $height) {
      foreach my $x (-$width .. $width) {
        print $grid{$x,$y} // ' ';
      }
      print "\n";
    }

    my %new_grid = %grid;
    my $count_new = 0;
    foreach my $y (-$height .. $height) {
      foreach my $x (-$width .. $width) {
        my $count = (($grid{$x-1,$y} || 0)
                     + ($grid{$x+1,$y} || 0)
                     + ($grid{$x,$y-1} || 0)
                     + ($grid{$x,$y+1} || 0));
        # print "$level  $x,$y  count=$count\n";
        if ($count == 1 || $count == 3) {
          $new_grid{$x,$y} = 1;
          $count_new++;
        }
      }
    }
    print "count new $count_new\n";
        %grid = %new_grid;
  }
  exit 0;
}

{
  # compare path against Cellular::Automata::Wolfram values

  require Cellular::Automata::Wolfram;
  my $width = 50;
  my $x_offset = int($width/2)-1;
  my $num_of_gens = $x_offset - 1;
 RULE: foreach my $rule (0 .. 255) {
    my $path = Math::PlanePath::CellularRule->new(rule=>$rule);
    my $auto = Cellular::Automata::Wolfram->new
      (rule=>$rule, width=>$width, num_of_gens=>$num_of_gens);
    my $gens = $auto->{'gens'};
    foreach my $y (0 .. $#$gens) {
      my $auto_str = $gens->[$y];
      my $path_str = '';
      foreach my $i (0 .. length($auto_str)-1) {
        my $x = $i - $x_offset;
        $path_str .= ($x < -$y || $x > $y ? substr($auto_str,$i,1)
                      : $path->xy_is_visited($x,$y) ? '1' : '0');
      }
      if ($auto_str ne $path_str) {
        print "$rule y=$y\n";
        print "auto $auto_str\n";
        print "path $path_str\n";
        print "\n";
        next RULE;
      }
    }
  }
  exit 0;

}
{
  my $rule = 124;
  my $path = Math::PlanePath::CellularRule->new(rule=>$rule);
  my @ys = (5..20);
  @ys = map{$_*2+1} @ys;
  my @ns = map{$path->xy_to_n(-$_,$_)
             }@ys;
  my @diffs = map {$ns[$_]-$ns[$_-1]} 1 .. $#ns;
  print "[",join(',',@diffs),"]\n";
  my @dds = map {$diffs[$_]-$diffs[$_-1]} 1 .. $#diffs;
  print "[",join(',',@dds),"]\n";
  exit 0;
}

{
  my $rule = 57;
  my $path = Math::PlanePath::CellularRule->new(rule=>$rule);
  my @ys = (5..20);
  @ys = map{$_*2+1} @ys;
  my @ns = map{$path->xy_to_n(-$_,$_)
             }@ys;
  my @diffs = map {$ns[$_]-$ns[$_-1]} 1 .. $#ns;
  print "[",join(',',@diffs),"]\n";
  my @dds = map {$diffs[$_]-$diffs[$_-1]} 1 .. $#diffs;
  print "[",join(',',@dds),"]\n";
  exit 0;
}

{
  my $rule = 57;
  my $path = Math::PlanePath::CellularRule->new(rule=>$rule);
  my @ys = (5..10);
  @ys = map{$_*2+1} @ys;
  print "[",join(',',@ys),"]\n";
  print "[",join(',',map{$path->xy_to_n(-$_,$_)
                         }@ys),"]\n";
  exit 0;
}

