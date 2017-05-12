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
use FindBin;
use MyGraphs;
use List::Util 'sum';

use lib 'devel/lib';

# uncomment this to run the ### lines
# use Smart::Comments;

{
  # subgraph relations among all graphs to N vertices -- graph drawing
  #
  # N=4
  #   all graphs          = mucho edges  [hog not]
  #     complement = some disconnecteds
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=26965
  #   all graphs, delta 1 = diam 6
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=26963
  #   connected graphs    = complete-6 less 3 edges (in a path)
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=748
  #   connected, delta 1  = square plus 2  "A Graph"
  #     https://hog.grinvin.org/ViewGraphInfo.action?id=945
  #     http://mathworld.wolfram.com/AGraph.html
  # N=3
  #   all graphs          = complete-4
  #   all graphs, delta 1 = path-4
  #   connected graphs    = path-2

  $|=1;
  my $num_vertices = 4;
  my $connected = 0;
  my $delta1 = 0;
  my $complement = 1;

  require Graph;
  my $iterator_func = make_graph_iterator_edge_aref
    (num_vertices_min => $num_vertices,
     num_vertices_max => $num_vertices,
     connected => $connected,
    );
  my @graphs;
  while (my $edge_aref = $iterator_func->()) {
    ### graph: edge_aref_string($edge_aref)
    push @graphs, Graph_from_edge_aref($edge_aref,
                                       num_vertices => $num_vertices);
  }
  print "total ",scalar(@graphs)," graphs\n";
  my $graph = Graph->new (undirected => 1);
  $graph->set_graph_attribute
    (name => "Subgraph Relations N=$num_vertices, "
     . ($connected ? ' Connected' : 'All'));
  foreach my $i (0 .. $#graphs) {
    my $n = $graphs[$i]->vertices;
    my $c = $graphs[$i]->is_connected ? 'C' : 'nc';
    my $s = "$graphs[$i]";
    print "$i [v=$n $s] subgraphs: ";
    foreach my $j (0 .. $#graphs) {
      next if $i==$j;
      if ($delta1
          && abs(scalar($graphs[$i]->edges)
                 - scalar($graphs[$j]->edges)) > 1) {
        next;
      }
      if (Graph_is_subgraph($graphs[$i], $graphs[$j])) {
        print "$j, ";
        $graph->add_edge($i, $j);
      }
    }
    print "\n";
  }

  my @named;
  require Graph::Maker::Star;
  push @named, [$num_vertices==4 ? 'claw' : 'star',
                Graph::Maker->new('star', N=>$num_vertices, undirected=>1)];

  require Graph::Maker::Linear;
  push @named, ['path',
                Graph::Maker->new('linear', N=>$num_vertices, undirected=>1)];

  require Graph::Maker::Complete;
  push @named, ['complete',
                Graph::Maker->new('complete', N=>$num_vertices, undirected=>1)];

  require Graph::Maker::Disconnected;
  push @named, ['disconnected',
                Graph::Maker->new('disconnected',
                                  N=>$num_vertices, undirected=>1)];

  require Graph::Maker::Cycle;
  push @named, ['cycle',
                Graph::Maker->new('cycle', N=>$num_vertices, undirected=>1)];
  {
    my $g = Graph::Maker->new('cycle', N=>$num_vertices, undirected=>1);
    $g->add_edge(1,int(($num_vertices+2)/2));
    push @named, ['cycle across',$g];
  }
  if ($num_vertices >= 4) {
    my $n = $num_vertices-1;
    my $g = Graph::Maker->new('cycle', N=>$n, undirected=>1);
    $g->add_edge(1,$num_vertices);
    push @named, ["cycle$n hanging",$g];
  }
  if ($num_vertices >= 4) {
    my $n = $num_vertices-1;
    my $g = Graph::Maker->new('cycle', N=>$n, undirected=>1);
    $g->add_vertex($num_vertices);
    push @named, ["cycle$n disc",$g];
  }
  foreach my $i (1 .. $num_vertices-1) {
    my $g = Graph::Maker->new('linear', N=>$i, undirected=>1);
    $g->add_vertices(1 .. $num_vertices);
    push @named, ["p-$i",$g];
  }
  if ($num_vertices >= 4) {
    my $g = Graph->new(undirected=>1);
    $g->add_vertices(1 .. $num_vertices);
    $g->add_edge(1,2);
    $g->add_edge(3,4);
    push @named, ["2-sep",$g];
  }
  foreach my $i (0 .. $#graphs) {
    foreach my $elem (@named) {
      if (Graph_is_isomorphic($graphs[$i],$elem->[1])) {
        print "$i = $elem->[0]\n";
        Graph_rename_vertex($graph, $i, $elem->[0]);
        last;
      }
    }
  }

  print "graph ",scalar($graph->edges)," edges ",
    scalar($graph->vertices), " vertices\n";

  if ($complement) {
    print "complement\n";
    $graph = complement($graph);
    print "graph ",scalar($graph->edges)," edges ",
      scalar($graph->vertices), " vertices\n";
    $graph->set_graph_attribute
      (name => $graph->get_graph_attribute('name') . ', Complement');
  }

  Graph_view($graph);
  Graph_print_tikz($graph);
  hog_searches_html($graph);
  exit 0;

  sub complement {
    my ($graph) = @_;
    my @vertices = $graph->vertices;
    $graph = $graph->complement;
    $graph->add_vertices(@vertices);
    return $graph;
  }
}

{
  # subgraph relations among graphs to N vertices -- counts
  #
  # all graphs:
  #   count
  #     0,1,6,46,409,6945
  #   count delta1
  #     0,1,3,14,74,571
  #     A245246 Number of ways to delete an edge (up to the outcome) in the simple unlabeled graphs on n nodes.
  #     A245246 ,0,1,3,14,74,571,6558,125066,4147388,
  #   non count
  #     0,0,0,9,152
  #   non count, both ways
  #     0,1,6,64,713
  #   total count, n*(n-1)/2 of A000088 num graphs 1,1,2,4,11,34,156,
  #     0,1,6,55,561
  #     apply(n->n*(n-1)/2, [1,1,2,4,11,34,156])==[0,0,1,6,55,561,12090]
  #
  # connected graphs:
  #   count         0,0,1,12,143,3244
  #   count_delta1  0,0,1,6,42,401
  #   non_count     0,0,0,3,67,2972
  #   total_count   0,0,1,15,210,6216
  #     total count, n*(n-1)/2 of A001349 num conn graphs 1,1,1,2,6,21,112,853,
  #   apply(n->n*(n-1)/2,[1,1,1,2,6,21,112,853])==[0,0,0,1,15,210,6216,363378]

  $|=1;
  require Graph;
  my @num_graphs;
  my @count;
  my @count_delta1;
  my @non_count;
  my @total_count;
  foreach my $num_vertices (1 .. 6) {

    my $iterator_func = make_graph_iterator_edge_aref
      (num_vertices_min => $num_vertices,
       num_vertices_max => $num_vertices,
       connected => 1,
      );
    my @graphs;
    while (my $edge_aref = $iterator_func->()) {
      ### graph: edge_aref_string($edge_aref)
      push @graphs, Graph_from_edge_aref($edge_aref,
                                         num_vertices => $num_vertices);
    }
    my $num_graphs = scalar(@graphs);
    push @num_graphs, $num_graphs;
    print "N=$num_vertices [$num_graphs] ";

    my $count = 0;
    my $count_delta1 = 0;
    my $non_count = 0;
    foreach my $i (0 .. $#graphs) {
      foreach my $j ($i+1 .. $#graphs) {

        if (Graph_is_subgraph($graphs[$i], $graphs[$j])
            || Graph_is_subgraph($graphs[$j], $graphs[$i])) {
          $count++;
          if (abs(scalar($graphs[$i]->edges) - scalar($graphs[$j]->edges)) <= 1) {
            $count_delta1++;
          }
        } else {
          $non_count++;
        }
      }
    }
    print " $count  $count_delta1\n";
    push @count, $count;
    push @count_delta1, $count_delta1;
    push @non_count, $non_count;
    push @total_count, $count + $non_count;
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@num_graphs, verbose=>1, name=>'num_graphs');
  Math::OEIS::Grep->search(array => \@count, verbose=>1, name=>'count');
  Math::OEIS::Grep->search(array => \@count_delta1, verbose=>1, name=>'count_delta1');
  Math::OEIS::Grep->search(array => \@non_count, verbose=>1, name=>'non_count');
  Math::OEIS::Grep->search(array => \@total_count, verbose=>1, name=>'total_count');
  exit 0;
}
{
  # longest induced path by search

  # dragon blobs
  # longest 0 cf v=0  [0 of]
  # longest 0 cf v=0  [0 of]
  # longest 0 cf v=0  [0 of]
  # longest 0 cf v=0  [0 of]
  # longest 3 cf v=4  [8 of] -2,1 -- -2,2 -- -3,2
  # longest 7 cf v=9  [4 of] -2,-1 -- -2,-2 -- -3,-2 -- -4,-2 -- -4,-1 -- -4,0 -- -5,0
  # longest 10 cf v=17  [4 of] -2,-6 -- -1,-6 -- -1,-5 -- -1,-4 -- -2,-4 -- -3,-4 -- -3,-5 -- -4,-5 -- -4,-4 -- -5,-4
  # longest 17 cf v=34  [32 of] ...
  # longest 31 cf v=68  [112 of] ...

  require Graph;
  my $graph = Graph->new (undirected=>1);
  $graph->add_cycle (0,1,2,3);
  $graph->add_path (2,4,5);
  $|=1;

  # search_induced_paths($graph,
  #                      sub {
  #                        my ($path) = @_;
  #                        ### $path
  #                        # print "path: ", join(', ',@$aref), "\n";
  #                      });
  # show_longest_induced_path($graph);

  require Graph::Maker::Dragon;
  foreach my $k (0 .. 10) {
    print "------------------------------------------------\n";
    my $graph = Graph::Maker->new('dragon',
                                  level => $k,
                                  arms => 1,
                                  part => 'blob',
                                  undirected=>1);
    # Graph_view($graph);
    show_longest_induced_path($graph);
  }
  exit 0;

  sub show_longest_induced_path {
    my ($graph) = @_;
    my @longest_path;
    my $count = 0;
    search_induced_paths($graph,
                         sub {
                           my @path = @_;
                           if (@_ > @longest_path) {
                             @longest_path = @_;
                             $count = 1;
                           } elsif (@_ == @longest_path) {
                             $count++;
                           }
                         });
    my $num_vertices = scalar($graph->vertices);
    my $length = scalar(@longest_path);
    my $longest_path = ($length > 10 ? '...' : join(' -- ',@longest_path));
    print "longest $length cf v=$num_vertices  [$count of] $longest_path\n";

    my $subgraph = $graph->subgraph(\@longest_path);
    Graph_xy_print($graph);
    Graph_xy_print($subgraph);
  }

  sub search_induced_paths {
    my ($graph, $callback) = @_;
    my @names = sort $graph->vertices;
    ### @names
    my $last_v = $#names;
    ### $last_v
    my %name_to_v = map { $names[$_] => $_ } 0 .. $#names;
    ### %name_to_v
    my @neighbours = map {[ sort {$a<=>$b}
                            map {$name_to_v{$_}}
                            $graph->neighbours($names[$_])
                          ]} 0 .. $#names;
    ### @neighbours
    my @path;
    my @path_try = ([0 .. $#names]);
    my @path_try_upto = (0);
    my @exclude;

    for (;;) {
      my $pos = scalar(@path);
      ### at: "path=".join(',',@path)." pos=$pos, try v=".($path_try[$pos]->[$path_try_upto[$pos]]//'undef')
      my $v = $path_try[$pos]->[$path_try_upto[$pos]++];
      if (! defined $v) {
        ### backtrack ...
        $v = pop @path;
        if (! defined $v) {
          return;
        }
        $exclude[$v]--;
        if (@path) {
          my $n = $neighbours[$path[-1]];
          ### unexclude prev neighbours: join(',',@$n)
          foreach my $neighbour (@$n) {
            $exclude[$neighbour]--;
          }
        }
        next;
      }

      if ($exclude[$v]) {
        ### skip excluded ...
        next;
      }

      push @path, $v;
      $callback->(map {$names[$_]} @path);

      if ($#path >= $last_v) {
        ### found path through all vertices ...
        pop @path;
        next;
      }

      ### add: "$v trying ".join(',',@{$neighbours[$v]})
      $exclude[$v]++;
      if ($pos >= 1) {
        my $n = $neighbours[$path[-2]];
        ### exclude prev neighbours: join(',',@$n)
        foreach my $neighbour (@$n) {
          $exclude[$neighbour]++;
        }
      }
      $pos++;
      $path_try[$pos] = $neighbours[$v];
      $path_try_upto[$pos] = 0;
    }
  }
}


{
  # Vertices as permutations, edges for some elements swap
  # 3 cycle of 6
  # 4 row   4-cycles cross connected
  #         truncated octahedral
  #         https://hog.grinvin.org/ViewGraphInfo.action?id=1391
  # 4 cycle rolling cube
  #         https://hog.grinvin.org/ViewGraphInfo.action?id=1292
  # 4 all   Reye graph = transposition graph order 4
  #         https://hog.grinvin.org/ViewGraphInfo.action?id=1277
  # 4 star  Nauru graph
  #         generalized Petersen, perumtation star graph 4
  #         https://hog.grinvin.org/ViewGraphInfo.action?id=1234
  require Graph;
  my $graph = Graph->new (undirected=>1);
  my $num_elements;
  my @swaps;

  $num_elements = 3;
  @swaps = ([0,1], [1,2]);         # 3-row = cycle of 6

  $num_elements = 4;
  @swaps = ([0,1], [0,2], [0,3], [1,2], [1,3], [2,3]);  # 4-all
  @swaps = ([0,1], [0,2], [0,3]);  # 4-star claw
  @swaps = ([0,1], [1,2], [2,3]);         # 4-row
  @swaps = ([0,1], [1,2], [2,3], [3,0]);  # 4-cycle

  my @pending = ([0 .. $num_elements-1]);
  my %seen;
  while (@pending) {
    my $from = pop @pending;
    my $from_str = join('',@$from);
    next if $seen{$from_str}++;

    foreach my $swap (@swaps) {
      my ($s1,$s2) = @$swap;
      my $to = [ @$from ];
      ($to->[$s1], $to->[$s2]) = ($to->[$s2], $to->[$s1]);
      my $to_str = join('',@$to);
      $graph->add_edge($from_str,$to_str);
      push @pending, $to;
    }
  }
#  Graph_view($graph);
#  Graph_print_tikz($graph);
  my $diameter = $graph->diameter;

  my @from = (0 .. $num_elements-1);
  my $from_str = join('',@from);
  my @rev = (reverse 0 .. $num_elements-1);
  my $rev_str = join('',@rev);
  print "diameter $diameter  from $from_str\n";
  print "reversal $rev_str distance=",
    $graph->path_length($from_str,$rev_str),"\n";
  foreach my $v (sort $graph->vertices) {
    my $len = $graph->path_length($from_str,$v) || 0;
    print " to $v distance $len",
      $len == $diameter ? "****" : "",
      "\n";
  }
  my @cycles;
  Graph_find_all_4cycles($graph, callback=>sub {
                           my @cycle = @_;
                           push @cycles, join(' -- ',@cycle);
                         });
  @cycles = sort @cycles;
  my $count = @cycles;
  foreach my $cycle (@cycles) {
    print "cycle $cycle\n";
  }
  print "count $count cycles\n";

  hog_searches_html($graph);
  exit 0;
}


{
  # neighbours
  require Graph;
  my $graph = Graph->new (undirected=>1);
  my $num_elements = 4;
  my @swaps = ([0,1], [1,2], [2,3]);

  my @pending = ([0 .. $num_elements-1]);
  my %seen;
  while (@pending) {
    my $from = pop @pending;
    my $from_str = join('-',@$from);
    next if $seen{$from_str}++;

    foreach my $swap (@swaps) {
      my ($s1,$s2) = @$swap;
      my $to = [ @$from ];
      ($to->[$s1], $to->[$s2]) = ($to->[$s2], $to->[$s1]);
      my $to_str = join('-',@$to);
      $graph->add_edge($from_str,$to_str);
      push @pending, $to;
    }
  }

  foreach my $x (sort $graph->vertices) {
    my @neighbours = $graph->neighbours($x);
    foreach my $y (@neighbours) {
      foreach (1 .. 5) {
        my $has_edge = $graph->has_edge($x, $y);
        print $has_edge;
        $has_edge = $graph->has_edge($y, $x);
        print $has_edge;
      }
    }
  }
  print "\n";

  Graph_find_all_4cycles($graph);
  exit 0;
}

{
  # count graphs with uniquely attained diameter
  # unique     1,1,1,2, 5, 25,185, 2459
  # not unique 0,0,1,4,16, 87,668, 8658
  # total      1,1,2,6,21,112,853,11117              A001349

  # count trees with uniquely attained diameter
  # unique     1,1,1,1,1,2, 3, 6,11, 24, 51,118, 271, 651,1572
  # not unique 0,0,0,1,2,4, 8,17,36, 82,184,433,1030,2508,6169
  # total      1,1,1,2,3,6,11,23,47,106,235,551,1301,3159,7741    A000055
  # increment    0,0,0,0,0, 0, 0, 0,  1,  4, 12,  36, 100, 271
  # diff = unique[n] - total[n-2]

  require Graph;
  my @count_unique;
  my @count_not;
  my @count_total;
  my @diff;
  foreach my $num_vertices (1 .. 8) {
    my $count_unique = 0;
    my $count_not = 0;
    my $count_total = 0;

    # my $iterator_func = make_tree_iterator_edge_aref
    #   (num_vertices => $num_vertices);
    my $iterator_func = make_graph_iterator_edge_aref
      (num_vertices => $num_vertices);
  GRAPH: while (my $edge_aref = $iterator_func->()) {
      my $graph = Graph_from_edge_aref($edge_aref);
      my $apsp = $graph->all_pairs_shortest_paths;
      my $diameter = $apsp->diameter;
      my $attained = 0;
      $count_total++;
      my @vertices = $graph->vertices;
      foreach my $i (0 .. $#vertices) {
        my $u = $vertices[$i];
        foreach my $j ($i+1 .. $#vertices) {
          my $v = $vertices[$j];
          if ($apsp->path_length($u,$v) == $diameter) {
            $attained++;
            if ($attained > 1) {
              $count_not++;
              next GRAPH;
            }
          }
        }
      }
      $count_unique++;
    }
    my $diff = (@count_total>=2 ? $count_unique - $count_total[-2] : 0);
    print "n=$num_vertices total $count_total unique $count_unique not $count_not  diff $diff\n";
    push @count_unique, $count_unique;
    push @count_not, $count_not;
    push @count_total, $count_total;
    if (@count_total >= 2) {
      push @diff, $diff;
    }
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@count_unique, verbose=>1, name=>'unique');
  Math::OEIS::Grep->search(array => \@count_not, verbose=>1, name=>'not');
  Math::OEIS::Grep->search(array => \@count_total, verbose=>1, name=>'total');
  Math::OEIS::Grep->search(array => \@diff, verbose=>1, name=>'diff');

  exit 0;
}
