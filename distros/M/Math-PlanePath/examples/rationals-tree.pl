#!/usr/bin/perl -w

# Copyright 2011, 2012, 2013 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# Usage: perl rationals-tree.pl
#
# Print the RationalsTree paths in tree form.
#

use 5.004;
use strict;
use List::Util 'max';
use Math::PlanePath::RationalsTree;
use Math::PlanePath::FractionsTree;

sub print_as_fractions {
  my ($path) = @_;

  my $n = $path->n_start;
  foreach (1) {
    my ($x,$y) = $path->n_to_xy($n++);
    print centre("$x/$y",64);
  }
  print "\n";

  print "                 /------------- -------------\\\n";
  foreach (1 .. 2) {
    my ($x,$y) = $path->n_to_xy($n++);
    print centre("$x/$y",32);
  }
  print "\n";

  print "         /----   ----\\                   /----   ----\\\n";
  foreach (1 .. 4) {
    my ($x,$y) = $path->n_to_xy($n++);
    print centre("$x/$y",16);
  }
  print "\n";

  print "     /   \\           /   \\           /   \\           /   \\\n";
  foreach (1 .. 8) {
    my ($x,$y) = $path->n_to_xy($n++);
    print centre("$x/$y",8);
  }
  print "\n";

  print " /   \\   /   \\   /   \\   /   \\   /   \\   /   \\   /   \\   /   \\\n";
  foreach (16 .. 31) {
    my ($x,$y) = $path->n_to_xy($n++);
    print centre("$x/$y",4);
  }
  print "\n";

  print "\n";
}

sub centre {
  my ($str, $width) = @_;
  my $extra = max (0, $width - length($str)); 
  my $left = int($extra/2);
  my $right = $extra - $left;
  return ' 'x$left . $str . ' 'x$right;
}

sub xy_to_cfrac_str {
  my ($x,$y) = @_;
  my @quotients;
  while ($x > 0 && $y > 0) {
    push @quotients, int($x/$y);
    $x %= $y;
    ($x,$y) = ($y,$x);
  }
  return "[".join(',',@quotients)."]";
}

sub print_as_cfracs {
  my ($path) = @_;

  my $n = $path->n_start;
  foreach (1) {
    my ($x,$y) = $path->n_to_xy($n++);
    print centre(xy_to_cfrac_str($x,$y), 72);
  }
  print "\n";

  print "                   /---------------  ---------------\\\n";
  foreach (1 .. 2) {
    my ($x,$y) = $path->n_to_xy($n++);
    print centre(xy_to_cfrac_str($x,$y), 36);
  }
  print "\n";

  print "          /-----   -----\\                     /-----   -----\\\n";
  foreach (1 .. 4) {
    my ($x,$y) = $path->n_to_xy($n++);
    print centre(xy_to_cfrac_str($x,$y), 18);
  }
  print "\n";

  print "      /   \\             /   \\             /   \\             /   \\\n";
  foreach (1 .. 8) {
    my ($x,$y) = $path->n_to_xy($n++);
    print centre(xy_to_cfrac_str($x,$y), 9);
  }
  print "\n";

  print "\n";
}

#------------------------------------------------------------------------------

my $rationals_type_arrayref
  = Math::PlanePath::RationalsTree->parameter_info_hash()->{'tree_type'}->{'choices'};
my $fractions_type_arrayref
  = Math::PlanePath::FractionsTree->parameter_info_hash()->{'tree_type'}->{'choices'};

print "RationalsTree\n";
print "-------------\n\n";

foreach my $tree_type (@$rationals_type_arrayref) {
  print "$tree_type tree\n";

  my $path = Math::PlanePath::RationalsTree->new
    (tree_type => $tree_type);
  print_as_fractions ($path);
}

print "\n";
print "FractionsTree\n";
print "-------------\n\n";

foreach my $tree_type (@$fractions_type_arrayref) {
  print "$tree_type tree\n";

  my $path = Math::PlanePath::FractionsTree->new
    (tree_type => $tree_type);
  print_as_fractions ($path);
}


print "\n";
print "-----------------------------------------------------------------------\n";
print "Or written as continued fraction quotients.\n";
print "\n";

print "RationalsTree\n";
print "-------------\n\n";

foreach my $tree_type (@$rationals_type_arrayref) {
  print "$tree_type tree\n";

  my $path = Math::PlanePath::RationalsTree->new
    (tree_type => $tree_type);
  print_as_cfracs ($path);
}

print "\n";
print "FractionsTree\n";
print "-------------\n\n";

foreach my $tree_type (@$fractions_type_arrayref) {
  print "$tree_type tree\n";

  my $path = Math::PlanePath::FractionsTree->new
    (tree_type => $tree_type);
  print_as_cfracs ($path);
}


exit 0;
