#!/usr/bin/perl -w

# Copyright 2017, 2018, 2019 Kevin Ryde
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
use File::Spec;
use File::Slurp;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Graph::Maker::ExcessConfigurations;

use lib 'devel/lib';
use MyGraphs;

plan tests => 2;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my $content = File::Slurp::read_file
    (File::Spec->catfile($FindBin::Bin,
                         File::Spec->updir,
                         'lib','Graph','Maker','ExcessConfigurations.pm'));
  $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
  $content = $&;
  my %shown;
  while ($content =~ /^    (\d+) +N=(\d+)/mg) {
    $shown{$2} = $1;
  }
  ok (scalar(keys %shown), 5);

  my $extras = 0;
  my %seen;
  foreach my $N (0 .. 6) {
    my $graph = Graph::Maker->new('excess_configurations', undirected => 1,
                                  N => $N);
    my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
    $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
    next if $seen{$g6_str}++;
    if (my $id = $shown{$N}) {
      MyGraphs::hog_compare($id, $g6_str);
    } else {
      if (MyGraphs::hog_grep($g6_str)) {
        MyTestHelpers::diag ("HOG N=$N not shown in POD");
        MyTestHelpers::diag ($g6_str);
        MyGraphs::Graph_view($graph);
        $extras++
      }
    }
  }
  ok ($extras, 0);
}


#------------------------------------------------------------------------------
exit 0;
