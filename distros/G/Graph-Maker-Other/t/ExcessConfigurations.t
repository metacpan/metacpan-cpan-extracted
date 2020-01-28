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

require Graph::Maker::ExcessConfigurations;

plan tests => 25;


#------------------------------------------------------------------------------
{
  my $want_version = 15;
  ok ($Graph::Maker::ExcessConfigurations::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::ExcessConfigurations->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::ExcessConfigurations->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::ExcessConfigurations->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# Specifics
{
  my $N = 3;
  my $graph = Graph::Maker->new('excess_configurations',
                                N => $N,
                                undirected => 1);
  ok (scalar($graph->vertices), 7);
  ok (scalar($graph->edges), 8);

  ok ($graph->degree('0'), 1);
  ok ($graph->degree('1'), 3);

  my @leaves = grep {$graph->degree($_)==1} $graph->vertices;
  ok (scalar(@leaves), 2);
  my @leaf_three = grep {$graph->degree($graph->neighbours($_))==3} @leaves;
  ok (scalar(@leaf_three), 1);
  ok ($leaf_three[0], '0');
}
{
  my $N = 4;
  my $graph = Graph::Maker->new('excess_configurations',
                                N => $N,
                                undirected => 1);
  ok (scalar($graph->vertices), 12);
  ok (scalar($graph->edges), 17);

  ok ($graph->degree('0'), 1);
  ok ($graph->degree('1'), 3);

  my @leaves = grep {$graph->degree($_)==1} $graph->vertices;
  ok (scalar(@leaves), 3);
  my @leaf_three = grep {$graph->degree($graph->neighbours($_))==3} @leaves;
  ok (scalar(@leaf_three), 1);
  ok ($leaf_three[0], '0');
}

#------------------------------------------------------------------------------

{
  # Janson, Knuth, Luczak, Pittel figure 1 (and 3).

  my $graph = Graph->new;
  $graph->add_edges(['0','1'],
                    ['1','0,1'], ['1','2'],

                    ['0,1','0,0,1'], ['0,1','1,1'],
                    ['2','0,0,1'], ['2','1,1'], ['2','3'],

                    ['0,0,1','0,0,0,1'], ['0,0,1','1,0,1'],
                    ['1,1','0,0,0,1'], ['1,1','1,0,1'],
                    ['1,1','0,2'], ['1,1','2,1'],
                    ['3','1,0,1'],['3','2,1'], ['3','4'],
                   );
  ok (scalar($graph->vertices), 12);
  my $excess = Graph::Maker->new('excess_configurations', N => 4);
  ok ("$graph", "$excess");
}
{
  my $excess = Graph::Maker->new('excess_configurations', N => 5);
  ok ($excess->out_degree('0,0,0,1'), 2);
  ok ($excess->out_degree('1,0,1'), 4);
  ok ($excess->out_degree('0,2'), 3);
  ok ($excess->out_degree('2,1'), 5);
  ok ($excess->out_degree('4'), 3);
}


#------------------------------------------------------------------------------
exit 0;
