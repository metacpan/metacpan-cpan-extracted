#!/usr/bin/perl -w

# Copyright 2018, 2019 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# This file is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  See the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.

use strict;
use 5.004;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use Graph::Maker::PlanePath;
use MyGraphs;

plan tests => 1;


#------------------------------------------------------------------------------
# POD HOG Shown in PlanePath/*.pm

my $extras = 0;
sub try {
  my %args = @_;
  my $key = delete $args{'key'};
  my $id = delete $args{'id'};
  my $graph = Graph::Maker->new('planepath', undirected => 1,
                                %args);
  my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
  $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
  # next if $seen{$g6_str}++;
  if ($id) {
    MyGraphs::hog_compare($id, $g6_str);
  } else {
    if (my $id = MyGraphs::hog_grep($g6_str)) {
      my $name = $graph->get_graph_attribute('name');
      MyTestHelpers::diag ("HOG $key not shown in POD: id $id");
      MyTestHelpers::diag ("Graph name: ",$name);
      MyTestHelpers::diag ($g6_str);
      # MyGraphs::Graph_view($graph);
      $extras++
    }
  }
}
{
  my %shown = (3 => 27008,
               4 => 27010,
               5 => 27012,
               6 => 33778,
               7 => 33780,
               8 => 33782,
              );
  foreach my $planepath ('AlternatePaper') {
    foreach my $level (3 .. 8) {
      my $key = $level;
      try (key => $key, id => $shown{$key},
           planepath => $planepath,
           level => $level);
    }
  }
}
{
  my %shown = (4 => 33739,
               5 => 33741,
               6 => 33743,
               7 => 33745,
               8 => 33747,
              );
  foreach my $planepath ('DragonCurve') {
    foreach my $level (4 .. 8) {
      my $key = $level;
      try (key => $key, id => $shown{$key},
           planepath => $planepath,
           level => $level);
    }
  }
}
{
  my %shown = (2 => 25149,
               3 => 25147,
              );
  foreach my $planepath ('R5DragonCurve') {
    foreach my $level (2 .. 5) {
      my $key = $level;
      try (key => $key, id => $shown{$key},
           planepath => $planepath,
           level => $level);
    }
  }
}
{
  my %shown = (2 => 21138,
               3 => 21140,
               4 => 33761,
               5 => 33763,
              );
  foreach my $planepath ('TerdragonCurve') {
    foreach my $level (2 .. 5) {
      my $key = $level;
      try (key => $key, id => $shown{$key},
           planepath => $planepath,
           level => $level);
    }
  }
}
ok ($extras, 0);


#------------------------------------------------------------------------------
exit 0;
