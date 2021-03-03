#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019, 2020, 2021 Kevin Ryde
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

plan tests => 92;

require Graph::Maker::Beineke;

#------------------------------------------------------------------------------
{
  my $want_version = 18;
  ok ($Graph::Maker::Beineke::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Beineke->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Beineke->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Beineke->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# G1 is claw
{
  require Graph::Maker::Star;
  my $claw = Graph::Maker->new('star', N=>4, undirected=>1);
  my $G1 = Graph::Maker->new('Beineke', G=>1, undirected=>1);
  ok ($G1 eq $claw, 1);
}

# G1 claw is subgraph of all others
{
  foreach my $i (1 .. 9) {
    my $G = Graph::Maker->new('Beineke', G=>$i, undirected=>1);
    ok ($G->has_edge(1,2) ? 1 : 0, 1);
    ok ($G->has_edge(1,3) ? 1 : 0, 1);
    ok ($G->has_edge(1,4) ? 1 : 0, 1, "G$i");
  }
}

#------------------------------------------------------------------------------
# G2 numbering  2
#              / \    is common to 2 through 9
#             3---1
#              \ /
#               4
{
  foreach my $i (2 .. 9) {
    my $G = Graph::Maker->new('Beineke', G=>$i, undirected=>1);
    ok ($G->has_edge(1,2) ? 1 : 0, 1);
    ok ($G->has_edge(1,3) ? 1 : 0, 1);
    ok ($G->has_edge(1,4) ? 1 : 0, 1);
    ok ($G->has_edge(2,3) ? 1 : 0, 1);
    ok ($G->has_edge(2,4) ? 1 : 0, ($i==3||$i==5||$i==6 ? 1 : 0), "G$i");
    ok ($G->has_edge(3,4) ? 1 : 0, 1);
  }
}

# G2 is wheel-5 less 1 edge 1-to-5
{
  require Graph::Maker::Complete;
  my $W5sub = Graph::Maker->new('wheel', N=>5, undirected=>1);
  $W5sub->delete_edge(1,5);
  my $G2 = Graph::Maker->new('Beineke', G=>2, undirected=>1);
  # print "G2     = $G2\n";
  # print "W5sub = $W5sub";
  ok ($G2 eq $W5sub, 1);
}

#------------------------------------------------------------------------------
# G3 is K5-e, complete less 1 edge 3-to-5
{
  require Graph::Maker::Complete;
  my $K5e = Graph::Maker->new('complete', N=>5, undirected=>1);
  $K5e->delete_edge(3,5);
  my $G3 = Graph::Maker->new('Beineke', G=>3, undirected=>1);
  # print "G3  = $G3\n";
  # print "K5e = $K5e\n";
  ok ($G3 eq $K5e, 1);
}

# G3 is wheel-5 plus 1 edge 2-to-4
{
  require Graph::Maker::Complete;
  my $W5plus = Graph::Maker->new('wheel', N=>5, undirected=>1);
  $W5plus->add_edge(2,4);
  my $G3 = Graph::Maker->new('Beineke', G=>3, undirected=>1);
  # print "G3     = $G3\n";
  # print "W5plus = $W5plus";
  ok ($G3 eq $W5plus, 1);
}

#------------------------------------------------------------------------------
# G4 is wheel-5 less edges
{
  require Graph::Maker::Complete;
  my $W6sub = Graph::Maker->new('wheel', N=>6, undirected=>1);
  $W6sub->delete_edge(1,5);
  $W6sub->delete_edge(1,6);
  $W6sub->delete_edge(5,6);
  my $G4 = Graph::Maker->new('Beineke', G=>4, undirected=>1);
  # print "G4    = $G4\n";
  # print "W6sub = $W6sub";
  ok ($G4 eq $W6sub, 1);
}

#------------------------------------------------------------------------------
# G5 is G3 changing edge 1-to-5 to new 5-to-6
{
  require Graph::Maker::Wheel;
  my $G3pm = Graph::Maker->new('Beineke', G=>3, undirected=>1);
  $G3pm->delete_edge(1,5);
  $G3pm->add_edge(5,6);
  my $G5 = Graph::Maker->new('Beineke', G=>5, undirected=>1);
  # print "G3pm = $G3pm\n";
  # print "G5   = $G5";
  ok ($G3pm eq $G5, 1);
}

#------------------------------------------------------------------------------
# G6 is wheel-6 mangled
{
  require Graph::Maker::Wheel;
  my $wheel = Graph::Maker->new('wheel', N=>6, undirected=>1);
  my $G6 = Graph::Maker->new('Beineke', G=>6, undirected=>1);
  $wheel->delete_edge(1,5);
  $wheel->delete_edge(1,6);
  $wheel->add_edge(2,4);
  $wheel->add_edge(2,5);
  $wheel->add_edge(4,6);
  # print "wheel = $wheel\n";
  # print "G6    = $G6\n";
  ok ($wheel eq $G6, 1);
}

# G6 is G5 plus 2 edges 2-to-6 and 4-to-6
{
  require Graph::Maker::Wheel;
  my $G5plus = Graph::Maker->new('Beineke', G=>5, undirected=>1);
  $G5plus->add_edge(2,6);
  $G5plus->add_edge(4,6);
  my $G6 = Graph::Maker->new('Beineke', G=>6, undirected=>1);
  # print "wheel = $wheel\n";
  # print "G6    = $G6\n";
  ok ($G5plus eq $G6, 1);
}

#------------------------------------------------------------------------------
# G7 is G4 plus edge 5-to-6
{
  require Graph::Maker::Wheel;
  my $G4plus = Graph::Maker->new('Beineke', G=>4, undirected=>1);
  $G4plus->add_edge(5,6);
  my $G7 = Graph::Maker->new('Beineke', G=>7, undirected=>1);
  # print "G4plus = $G4plus\n";
  # print "G7   = $G7\n";
  ok ($G4plus eq $G7, 1);
}

# G7 is wheel-6 less 2 edges
{
  require Graph::Maker::Wheel;
  my $wheel = Graph::Maker->new('wheel', N=>6, undirected=>1);
  my $G7 = Graph::Maker->new('Beineke', G=>7, undirected=>1);
  $wheel->delete_edge(1,5);
  $wheel->delete_edge(1,6);
  # print "wheel = $wheel\n";
  # print "G7    = $G7\n";
  ok ($wheel eq $G7, 1);
}

#------------------------------------------------------------------------------
# G8 is wheel-6 with vertex 6 mangled
{
  require Graph::Maker::Wheel;
  my $wheel = Graph::Maker->new('wheel', N=>6, undirected=>1);
  my $G8 = Graph::Maker->new('Beineke', G=>8, undirected=>1);
  $wheel->delete_edge(1,6);
  $wheel->delete_edge(2,6);
  $wheel->add_edge(4,6);
  # print "wheel = $wheel\n";
  # print "G8    = $G8\n";
  ok ($wheel eq $G8, 1);
}

# G8 by square picture
{
  my $G8 = Graph::Maker->new('Beineke', G=>8, undirected=>1);
  my $graph = Graph->new(undirected=>1);
  $graph->add_cycle(1,2,3,4,6,5);
  $graph->add_path(3,1,4,5);
  # print "graph = $graph\n";
  # print "G8    = $G8\n";
  ok ($graph eq $G8, 1);
}

#------------------------------------------------------------------------------
# G9 is wheel-6
{
  require Graph::Maker::Wheel;
  my $wheel = Graph::Maker->new('wheel', N=>6, undirected=>1);
  my $G9 = Graph::Maker->new('Beineke', G=>9, undirected=>1);
  ok ($G9 eq $wheel, 1);
}

#------------------------------------------------------------------------------
exit 0;
