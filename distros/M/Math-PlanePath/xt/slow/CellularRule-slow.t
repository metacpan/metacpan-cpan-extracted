#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

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

use 5.004;
use strict;
use List::Util 'min','max';
use Test;
plan tests => 637;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings(); }

# uncomment this to run the ### lines
#use Smart::Comments;

require Math::PlanePath::CellularRule;


#------------------------------------------------------------------------------
# rules_are_equiv()

sub paths_are_equiv {
  my ($path1, $path2) = @_;
  foreach my $y (0 .. 6) {
    foreach my $x (-$y .. $y) {
      if ((!! $path1->xy_is_visited($x,$y))
          != (!! $path2->xy_is_visited($x,$y))) {
        return 0;
      }
    }
  }
  return 1;
}

foreach my $rule1 (0 .. 255) {
  my $path1 = Math::PlanePath::CellularRule->new (rule => $rule1);
  foreach my $rule2 (0 .. 255) {
    my $path2 = Math::PlanePath::CellularRule->new (rule => $rule2);

    my $got = Math::PlanePath::CellularRule->_NOTWORKING__rules_are_equiv($rule1,$rule2) ? 1 : 0;
    my $want = paths_are_equiv($path1,$path2);
    ok ($got, $want, "rules_are_equiv($rule1,$rule2)");
    if ($got != $want) {
      MyTestHelpers::diag(path_str($path1));
      MyTestHelpers::diag(path_str($path2));
    }
  }
}

#------------------------------------------------------------------------------
# rule_to_mirror()

sub paths_are_mirror {
  my ($path1, $path2) = @_;
  foreach my $y (0 .. 6) {
    foreach my $x (-$y .. $y) {
      if ((!!$path1->xy_is_visited($x,$y))
          != (!!$path2->xy_is_visited(-$x,$y))) {
        return 0;
      }
    }
  }
  return 1;
}

foreach my $rule (0 .. 255) {
  my $mirror_rule = Math::PlanePath::CellularRule->_UNDOCUMENTED__rule_to_mirror($rule);
  my $path1 = Math::PlanePath::CellularRule->new (rule => $rule);
  my $path2 = Math::PlanePath::CellularRule->new (rule => $mirror_rule);
  my $are_mirror = paths_are_mirror($path1,$path2);
  ok ($are_mirror, 1, "rule_to_mirror() rule=$rule got_rule=$mirror_rule");
  if (! $are_mirror) {
    MyTestHelpers::diag(path_str($path1));
    MyTestHelpers::diag(path_str($path2));
  }
}

#------------------------------------------------------------------------------
# rule_is_finite()

sub path_is_finite {
  my ($path) = @_;
  foreach my $y (4 .. 6) {
    foreach my $x (-$y .. $y) {
      if ($path->xy_is_visited($x,$y)) {
        return 0;
      }
    }
  }
  return 1;
}

foreach my $rule (0 .. 255) {
  my $path = Math::PlanePath::CellularRule->new (rule => $rule);
  my $got = Math::PlanePath::CellularRule->_UNDOCUMENTED__rule_is_finite($rule) ? 1 : 0;
  my $want = path_is_finite($path) ? 1 : 0;
  ok ($got, $want, "rule_is_finite() rule=$rule");
  if ($got != $want) {
    MyTestHelpers::diag (path_str($path));
  }
}

#------------------------------------------------------------------------------
# rule_is_symmetric()

sub path_is_symmetric {
  my ($path) = @_;
  foreach my $y (1 .. 8) {
    foreach my $x (1 .. $y) {
      if ((!!$path->xy_is_visited($x,$y)) != (!!$path->xy_is_visited(-$x,$y))) {
        return 0;
      }
    }
  }
  return 1;
}

foreach my $rule (0 .. 255) {
  my $path = Math::PlanePath::CellularRule->new (rule => $rule);
  my $got_symmetric = Math::PlanePath::CellularRule->_NOTWORKING__rule_is_symmetric($rule) ? 1 : 0;
  my $want_symmetric = path_is_symmetric($path) ? 1 : 0;
  ok ($got_symmetric, $want_symmetric, "rule_is_symmetric() rule=$rule");
  if ($got_symmetric != $want_symmetric) {
    MyTestHelpers::diag (path_str($path));
  }
}

sub path_str {
  my ($path) = @_;
  my $str = '';
  foreach my $y (reverse 0 .. 6) {
    $str .= "$y  ";
    foreach my $x (-6 .. 6) {
      $str .= $path->xy_is_visited($x,$y) ? ' *' : '  ';
    }
    if ($y == 6) {
      $str .= "    rule=$path->{'rule'} = ".sprintf('%08b',$path->{'rule'});
    }
    $str .= "\n";
  }
  return $str;
}

#------------------------------------------------------------------------------
exit 0;
