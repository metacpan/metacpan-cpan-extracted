#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
#
# This file is part of Graph-Maker-Other.
#
# Graph-Maker-Other is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Maker-Other is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Maker-Other.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use Math::Complex 'pi';

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  foreach my $k (7,
                 9,
                ) {
    print "k=$k\n";

    my %seen_pair;
    my @triples;
    foreach my $A (1 .. $k) {
      foreach my $B (1 .. $k) {
        next if $A == $B;
        foreach my $c (1 .. $k) {
          next if $A == $c;
          next if $B == $c;
          my @triple = ($A,$B,$c);
          @triple = sort {$a<=>$b} @triple;
          my $Ab = "$triple[0],$triple[1]";
          my $Ac = "$triple[0],$triple[2]";
          my $Bc = "$triple[1],$triple[2]";
          next if $seen_pair{$Ab};
          next if $seen_pair{$Ac};
          next if $seen_pair{$Bc};

          push @triples, \@triple;
          $seen_pair{$Ab} = 1;
          $seen_pair{$Ac} = 1;
          $seen_pair{$Bc} = 1;
          my $pairs = join(' ',keys %seen_pair);
          my $triple = join(',',@triple);
          print "triple $triple  (pairs $pairs)\n";
        }
      }
    }
    my $num_pairs = scalar(keys %seen_pair);
    print "num_pairs pairs $num_pairs\n";

    # require Graph;
    # my $graph = Graph->new(undirected => 1);
    # foreach my $triple (@triples) {
    #   $graph->add_cycle(@$triple);
    # }
    # Graph_view($graph);

    require GraphViz2;
    my $graphviz2 = GraphViz2->new (directed => 0,
                                    graph => { margin => 0,
                                               sep => .5,
                                               overlap => "scale",
                                             },
                                    node => {
                                            });
    foreach my $v (1 .. $k) {
      my $x = cos(2*pi()/$k * $v);
      my $y = sin(2*pi()/$k * $v);
      # $y = -$y;
      $graphviz2->add_node(name => $v,
                           pin => 1,
                           pos => "$x,$y");
    }
    foreach my $triple (@triples) {
      foreach my $i (0 .. $#$triple) {
        $graphviz2->add_edge(from => $triple->[$i-1], to => $triple->[$i]);
      }
    }

    $graphviz2->run(format => 'xlib',
                    driver => 'neato',
                   );
    # print $graphviz2->dot_input;
  }
  exit 0;
}


