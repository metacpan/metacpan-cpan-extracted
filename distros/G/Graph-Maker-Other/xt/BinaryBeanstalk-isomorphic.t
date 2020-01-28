#!/usr/bin/perl -w

# Copyright 2017, 2018, 2019, 2020 Kevin Ryde
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
use FindBin;
use File::Slurp;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Graph::Maker::BinaryBeanstalk;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs;

plan tests => 3;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  # my %shown_height = (1 => 1,
  #                     2 => 2,
  #                     4 => 3,
  #                     6 => 4,
  #                     8 => 5);
  # 
  # my %shown = (1  => 1310,   # N=1 single vertex
  #              2  => 19655,  # N=2 path-2
  #              3  => 32234,  # N=3 path-3
  # 
  #              4  => 500,    # height=3
  #              5  => 30,
  #              6  => 334,    # height=4
  #              7  => 714,
  #              8  => 502,    # height=5
  #              13 => 60,
  #             );

  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','BinaryBeanstalk.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $count = 0;
    while ($content =~ /^ +(?<id>\d+) +N=(?<N>\d+)( +\(height=(?<height>\d+)\))?/mg) {
      $count++;
      my $id    = $+{'id'};
      my $N     = $+{'N'};
      my $height = $+{'height'};
      $shown{"N=$N"} = $+{'id'};
      if (defined $height) {
        $shown{"height=$height"} = $+{'id'};
      }
    }
    ok ($count, 9, 'HOG ID number of lines');
  }
  ok (scalar(keys %shown), 14);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my %seen;
  my $try = sub {
    my @params = @_;
    my $graph = Graph::Maker->new('binary_beanstalk', undirected=>1, @params);
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    my $key = join('=',@params);
    if (my $id = $shown{$key}) {
      MyGraphs::hog_compare($id, $g6_str);
      $compared++;
    } else {
      $others++;
      if (MyGraphs::hog_grep($g6_str)) {
        my $name = $graph->get_graph_attribute('name');
        MyTestHelpers::diag ("HOG $key not shown in POD");
        MyTestHelpers::diag ($name);
        MyTestHelpers::diag ($g6_str);
        MyGraphs::Graph_view($graph);
        $extras++;
      }
    }
  };
  foreach my $N (0 .. 64) {
    $try->(N => $N);
  }
  foreach my $height (0 .. 20) {
    $try->(height => $height);
  }
  ok ($extras, 0);
}

#------------------------------------------------------------------------------
exit 0;
