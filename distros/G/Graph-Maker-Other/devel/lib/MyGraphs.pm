# Copyright 2015, 2016, 2017, 2018, 2019, 2020 Kevin Hyde
#
# This file is shared by a couple of distributions.
#
# This file is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# This file is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this file.  If not, see <http://www.gnu.org/licenses/>.


# (Some tests in gmaker xt/MyGraphs-various.t)

package MyGraphs;
use 5.010;
use strict;
use warnings;
use Carp 'croak';
use List::Util 'min','max','sum','minstr';
use Scalar::Util 'blessed';
use File::Spec;
use File::HomeDir;
use Math::Trig ();
use POSIX 'ceil';
my @ipc;

use base 'Exporter';
use vars '@EXPORT_OK';
@EXPORT_OK = ('Graph_Easy_view',
              'Graph_Easy_edges_string',
              'Graph_Easy_edge_list_string',
              'edge_aref_to_Graph_Easy',
              'Graph_Easy_line_graph',
              'Graph_Easy_print_adjacency_matrix',

              'edge_aref_to_Graph',
              'Graph_view',
              'Graph_tree_print','Graph_xy_print',
              'Graph_print_tikz',
              'Graph_branch_reduce',
              'Graph_is_regular',
              'Graph_is_isomorphic',
              'Graph_is_subgraph',
              'Graph_is_induced_subgraph',
              'Graph_from_edge_aref',
              'Graph_line_graph',
              'Graph_is_line_graph_by_Beineke',
              'Graph_Wiener_index','Graph_Wiener_part_at_vertex',
              'Graph_terminal_Wiener_index','Graph_terminal_Wiener_part_at_vertex',
              'Graph_to_sparse6_str',
              'Graph_to_graph6_str',
              'Graph_from_graph6_str',

              'Graph_triangle_is_even',
              'Graph_triangle_search','Graph_find_triangle',
              'Graph_has_triangle','Graph_triangle_count',

              'Graph_claw_search',
              'Graph_has_claw','Graph_claw_count','Graph_claw_count',

              'Graph_clique_number',
              'Graph_width_list',

              'Graph_is_cycles',
              'Graph_find_all_cycles',
              'Graph_find_all_4cycles',
              'Graph_is_hanging_cycle',
              'Graph_delete_hanging_cycles',
              'Graph_girth',  # smallest cycle
              'Graph_is_Hamiltonian',

              'Graph_rename_vertex','Graph_pad_degree',
              'Graph_eccentricity_path',
              'Graph_tree_centre_vertices',
              'Graph_tree_domnum',
              'Graph_tree_domsets_count','Graph_tree_minimal_domsets_count',
              'Graph_is_domset','Graph_is_minimal_domset',
              'Graph_domset_is_minimal',
              'Graph_minimal_domsets_count_by_pred',
              'Graph_is_total_domset',

              'edge_aref_num_vertices',
              'edge_aref_is_subgraph',
              'edge_aref_is_induced_subgraph',
              'edge_aref_degrees_allow_subgraph',
              'edge_aref_string',
              'edge_aref_to_parent_aref',
              'edge_aref_degrees',
              'edge_aref_degrees_distinct',
              'edge_aref_is_regular',
              'parent_aref_to_edge_aref',
              'parent_aref_to_Graph_Easy',

              'graph6_str_to_canonical',
              'graph6_view',

              'make_tree_iterator_edge_aref',
              'make_graph_iterator_edge_aref',
              'hog_searches_html','hog_grep',
              'postscript_view_file',

              'Graph_to_GraphViz2',

              'Graph_subtree_depth',
              'Graph_subtree_children',

              'Graph_star_replacement','Graph_cycle_replacement',
             );

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
# Graph::Easy extras

# $filename is a postscript file
#   synchronous => 1, wait for viewer to exit before returning.
sub postscript_view_file {
  my ($filename, %options) = @_;
  require IPC::Run;
  my @command = ('gv',
                 '--scale=.7',
                 $filename);
  if ($options{'synchronous'}) {
    IPC::Run::run(\@command);
  } else {
    push @ipc, IPC::Run::start(\@command,'&');
  }
}
END {
  foreach my $h (@ipc) {
    $h->finish;
  }
}

# $graph is a Graph::Easy object, show it graphically
#   synchronous => 1, wait for viewer to exit before returning.
sub Graph_Easy_view {
  my ($graph, %options) = @_;

  require File::Temp;
  my $dot = File::Temp->new (UNLINK => 0, SUFFIX => '.dot');
  my $dot_filename = $dot->filename;

  # per Graph::Easy::As_graphviz
  print $dot $graph->as_graphviz;

  graphviz_view_file($dot_filename, %options);
}

# $str is DOT format graph
sub graphviz_view {
  my ($str) = @_;
  graphviz_view_file(\$str);
}
# $filename is a filename string or a scalar ref to string contents
sub graphviz_view_file {
  my ($filename, %options) = @_;

  require File::Temp;
  my $ps = File::Temp->new (UNLINK => 0, SUFFIX => '.ps');
  my $ps_filename = $ps->filename;
  ### $ps_filename

  require IPC::Run;
  IPC::Run::run(['dot','-Tps',
                ],
                '<',$filename, '>',$ps_filename);
  # ['neato','-Tps','-s2']

  postscript_view_file ($ps->filename, %options);
}

sub Graph_Easy_branch_reduce {
  my ($graph) = @_;

  foreach my $node ($graph->nodes) {
    my @predecessors = $node->predecessors();
    my @successors = $node->successors();
    if (@predecessors == 1 && @successors == 1) {
      $graph->del_node($node);
      $graph->add_edge($predecessors[0], $successors[0]);
    }
  }
}
sub Graph_Easy_leaf_reduce {
  my ($graph) = @_;
  # print "$graph";

  foreach my $node ($graph->nodes) {
    my @successors = $node->successors;
    @successors == 2 || next;
    if (Graph_Easy_Node_is_leaf($successors[0])
        && Graph_Easy_Node_is_leaf($successors[1])) {
      $graph->del_node($successors[1]);
    }
  }
}
sub Graph_Easy_Node_is_leaf {
  my ($node) = @_;
  my @successors = $node->successors;
  return (@successors == 0);
}

sub Graph_Easy_edges_string {
  my ($easy) = @_;
  Graph_Easy_edge_list_string($easy->edges);
}
sub Graph_Easy_edge_list_string {
  my @edges = map { [ $_->from->name, $_->to->name ] } @_;
  @edges = sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } @edges;
  return join(' ',map {join('-',@$_)} @edges);
}

sub Graph_Easy_print_adjacency_matrix {
  my ($easy) = @_;
  my $has_edge_either = ($easy->is_directed
                         ? \&Graph::Easy::As_graph6::_has_edge_either_directed
                         : 'has_edge');
  my @vertices = $easy->sorted_nodes('name');
  foreach my $from (0 .. $#vertices) {
    foreach my $to (0 .. $#vertices) {
      print $easy->$has_edge_either($vertices[$from], $vertices[$to]) ? ' 1' : ' 0';
    }
    print "\n";
  }
}

#------------------------------------------------------------------------------
# Graph.pm extras

sub Graph_sorted_vertices {
  my ($graph) = @_;
  my @vertices = $graph->vertices;
  my $func = cmp_func(@vertices);
  return sort $func @vertices;
}

sub Graph_print_adjacency_matrix {
  my ($graph, $fh) = @_;
  $fh //= \*STDOUT;
  my @vertices = Graph_sorted_vertices($graph);
  print $fh "[" or die;
  foreach my $from (0 .. $#vertices) {
    foreach my $to (0 .. $#vertices) {
      print$fh $graph->has_edge($vertices[$from], $vertices[$to]) ? '1' : '0',
        $to==$#vertices ? ($from==$#vertices ? ']' : ';') : ','
        or die;
    }
    # print "\n";
  }
}
sub Graph_loopcount {
  my ($graph) = @_;
  my $loopcount = 0;
  foreach my $edge ($graph->edges) {
    $loopcount += ($edge->[0] eq $edge->[1]);
  }
  return $loopcount;
}


# modify $graph to branch reduce, meaning all degree-2 vertices are
# contracted out by deleting and joining their neighbours with an edge
sub Graph_branch_reduce {
  my ($graph) = @_;
  ### Graph_branch_reduce() ...

  my $more;
  do {
    $more = 0;
    foreach my $v ($graph->vertices) {
      my @neighbours = $graph->neighbours($v);
      if (@neighbours == 2) {
        ### delete: $v
        $graph->delete_vertex($v);
        $graph->add_edge($neighbours[0], $neighbours[1]);
        $more = 1;
      }
    }
  } while ($more);
}

# return a list of the immediate children of vertex $v
# children are vertices compared numerically $child >= $v
sub Graph_vertex_children {
  my ($graph, $v, %options) = @_;
  my $cmp = $options{'cmp'} || cmp_func($graph->vertices);
  my @children = grep {$cmp->($_,$v)>0} $graph->neighbours($v);
  return @children;
}
sub Graph_vertex_num_children {
  my ($graph, $v, %options) = @_;
  my @children = Graph_vertex_children($graph,$v, %options);
  return scalar(@children);
}

# $graph is a Graph.pm, show it graphically
#   synchronous => 1, wait for viewer to exit before returning.
#   xy => 1, treat each vertex name as x,y coordinates
sub Graph_view {
  my ($graph, %options) = @_;
  ### Graph_view(): %options

  my @vertices = $graph->vertices;
  my $is_xy = ($graph->get_graph_attribute('vertex_name_type_xy')
               || $graph->get_graph_attribute('xy')
               || (@vertices
                   && defined $graph->get_vertex_attribute($vertices[0],'xy'))
               || do {
                 my $type = $graph->get_graph_attribute('vertex_name_type');
                 defined $type && $type =~ /^xy/ }
               || do {
                 my ($v) = $graph->vertices;
                 defined $v && defined($graph->get_vertex_attribute($v,'x')) });
  ### $is_xy
  if ($is_xy) {
    my $graphviz2 = Graph_to_GraphViz2($graph, %options);
    GraphViz2_view($graphviz2, driver=>'neato', %options);
    return;
  }

  {
    my $graphviz2 = Graph_to_GraphViz2($graph, %options);
    GraphViz2_view($graphviz2, %options);
    return;
  }

  ### Convert ...
  require Graph::Convert;
  my $easy = Graph::Convert->as_graph_easy($graph);
  ### flow: $graph->get_graph_attribute('flow')
  ### flow: $graph->get_graph_attribute('flow') // 'south'
  $easy->set_attribute('flow',
                       $graph->get_graph_attribute('flow') // 'south');
  if (defined(my $name = $graph->get_graph_attribute('name'))) {
    $easy->set_attribute('label',$name);
  }
  Graph_Easy_view($easy, %options);
  # print "Graph: ", $graph->is_directed ? "directed\n" : "undirected\n";
  # print "Easy:  ", $easy->is_directed ? "directed\n" : "undirected\n";
}

sub Graph_vertex_parent {
  my ($graph, $v, %options) = @_;
  my $cmp = $options{'cmp'} || cmp_func($graph->vertices);
  my @parents = grep {$cmp->($_,$v)<=0} $graph->neighbours($v);
  return $parents[0];
}
sub Graph_vertex_depth {
  my ($graph, $v) = @_;
  my $depth = 0;
  while ($v = Graph_vertex_parent($graph,$v)) {
    $depth++;
  }
  return $depth;
}
sub Graph_tree_root {
  my ($graph) = @_;
  if (defined (my $root = $graph->get_graph_attribute('root'))) {
    return $root;
  }
  if (defined(my $root = $graph->get_graph_attribute('root_vertex'))) {
    return $root;
  }
  foreach my $v ($graph->vertices) {
    if ($v =~ /^0+$/) {
      return $v;       # 0 or 00 or 000 etc
    }
  }
  if ($graph->has_vertex(1)) {
    return 1;
  }
  croak "No tree root found";
}

# Note: This depends on the Graph_vertex_children() vertex numbering.
sub Graph_tree_height {
  my ($graph, $root) = @_;
  $root //= Graph_tree_root($graph);
  ### $root
  my $height = 0;
  my @pending = ($root);
  my $depth = 0;
  for (;;) {
    @pending = map {Graph_vertex_children($graph,$_)} @pending;
    last unless @pending;
    $depth++;
  }
  return $depth;
}

# Return a list of arrayrefs [$v,$v,...] which are the vertices at
# successive depths of tree $graph.  The first arrayref contains the tree root.
# Within each row vertices are sorted first by parent, then by given cmp.
sub Graph_vertices_by_depth {
  my ($graph, %options) = @_;
  my $root = $options{'root'} // Graph_tree_root($graph);
  my @ret = ([$root]);
  my $cmp = $options{'cmp'} || cmp_func($graph->vertices);
  my %seen = ($root => 1);
  for (;;) {
    my @row = map { sort $cmp
                      grep {!$seen{$_}++}
                      $graph->neighbours($_) } @{$ret[-1]};
    @row || last;
    push @ret, \@row;
  }
  return @ret;
}

# return a list of all the descendents of vertex $v
# children are vertices compared numerically $child >= $v
sub Graph_tree_descendents {
  my ($graph, $v) = @_;
  my @ret;
  my @pending = ($v);
  while (@pending) {
    @pending = map {Graph_vertex_children($graph,$_)} @pending;
    push @ret, @pending;
  }
  return @ret;
}

sub cmp_numeric ($$) {
  my ($a, $b) = @_;
  return $a <=> $b;
}
sub cmp_alphabetic ($$) {
  my ($a, $b) = @_;
  return $a cmp $b;
}
sub cmp_func {
  return (all_looks_like_number(@_) ? \&cmp_numeric : \&cmp_alphabetic);
}

sub Graph_tree_print {
  my ($graph, %options) = @_;
  ### Graph_tree_print() ...

  my $flow = ($options{'flow'} // 'down');
  my $hat = '^';
  my $slash = '/';
  my $backslash = '\\';
  if ($flow eq 'up') {
    $hat = 'v';
    $slash = '\\';
    $backslash = '/';
  }

  {
    # by successive adjustment
    my $gap = 2;
    my $sibling_gap = 1;

    my $cmp = $options{'cmp'} || cmp_func($graph->vertices);
    ### numeric: $cmp==\&cmp_numeric
    my @vertices = $graph->vertices;
    my @vertices_by_depth = Graph_vertices_by_depth($graph, cmp => $cmp);
    ### @vertices_by_depth
    my %column;
    my %children;

    foreach my $v (@vertices) {
      $children{$v} = [ sort $cmp Graph_vertex_children($graph,$v,cmp=>$cmp) ];
      $column{$v} = 0;
      ### children: "$v children ".join(',',@{$children{$v}})
    }

    my $are_siblings = sub {
      my ($v1,$v2) = @_;
      my $p1 = Graph_vertex_parent($graph,$v1, cmp=>$cmp) // return 0;
      my $p2 = Graph_vertex_parent($graph,$v2, cmp=>$cmp) // return 0;
      return $p1 eq $p2;
    };

  OUTER: for (my $limit = 0; $limit < 50; $limit++) {
      # avoid overlaps within row
      foreach my $depth (0 .. $#vertices_by_depth) {
        my $aref = $vertices_by_depth[$depth];
        foreach my $i (1 .. $#$aref) {
          my $v1 = $aref->[$i-1];
          my $v2 = $aref->[$i];
          my $c = $column{$v1} + length($v1)
            + ($are_siblings->($v1,$v2) ? $sibling_gap : $gap);
          if ($column{$v2} < $c) {
            ### overlap in row: "depth=$depth  $v2 to column $c"
            $column{$v2} = $c;
            next OUTER;
          }
        }
      }

      # parent half-way along children,
      # or children moved up if parent further along
      foreach my $p (@vertices) {
        my $children_aref = $children{$p};
        next unless @$children_aref;
        my $min = $column{$children_aref->[0]};
        my $max = $column{$children_aref->[-1]} + length($children_aref->[-1]);
        my $c = int(($max + $min - length($p))/2);
        if ($column{$p} < $c) {
          ### parent: "parent p=$p move up to middle $c  ($min to $max)"
          $column{$p} = $c;
          next OUTER;
        }
        if ($column{$p} > $c) {
          my $v = $children_aref->[0];
          $column{$v}++;
          ### parent: "parent $p at $column{$v} > mid $c, advance first child c=$v (".join(',',@$children_aref).") to column $column{$v}"
          next OUTER;
        }
      }

      # leading leaf child moves up to its sibling
      foreach my $parent (@vertices) {
        my $children_aref = $children{$parent};
        my $v1 = $children_aref->[0] // next;
        my $v2 = $children_aref->[1] // next;
        next if @{$children{$v1}}; # want $v1 leaf
        my $c = $column{$v2} - length($v1) - $sibling_gap;
        if ($column{$v1} < $c) {
          $column{$v1} = $c;
          next OUTER;
        }
      }
      last;
    }

    my $total_column = max(map {$column{$_}+length($_)} @vertices) + 3;
    my @lines;
    foreach my $depth (0 .. $#vertices_by_depth) {
      my $aref = $vertices_by_depth[$depth];
      my $c = 0;
      my $line = '';
      foreach my $v (@$aref) {
        $column{$v} ||= 0;
        while ($c < ($column{$v}||0)) {
          $line .= " ";
          $c++;
        }
        $line .= $v . " ";
        $c += length($v)+1;
      }
      while ($c < $total_column) {
        $line .= " ";
        $c++;
      }
      my $count = @$aref;
      $line .= "count $count\n";
      push @lines, $line;

      $line = '';
      $c = 0;
      if ($depth < $#vertices_by_depth) {
        my @lines;
        foreach my $v (@$aref) {
          my $children_aref = $children{$v};
          next unless @$children_aref;
          my $min = $column{$children_aref->[0]};
          my $max = $column{$children_aref->[-1]} + length($children_aref->[-1]);

          if (@$children_aref > 1) {
            if (length($children_aref->[0]) > 1) { $min++; }
            if (length($children_aref->[-1]) > 1) { $max--; }
          }

          my $mid = int($column{$v} + length($v)/2);
          while ($c < $min) { $line .= ' '; $c++; }
          # while ($c < $max) { print($c == $mid ? '|' : '_'); $c++; }
          while ($c < $max) {
            $line .= ($c == $mid && @$children_aref != 2 ? '|'
                      : @$children_aref == 1 ? ' '
                      : $c == $min ? $slash
                      : $c == $max-1 ? $backslash
                      : $c == $mid ? ($max-$min <=3 && $flow eq 'up' ? ' ' : $hat)
                      : '-'); $c++;
          }
        }
      }
      $line .= "\n";
      push @lines, $line;
    }
    if ($flow eq 'up') {
      @lines = reverse @lines;
    }
    print @lines;
    return;
  }

  {
    my @vertices_by_depth = Graph_vertices_by_depth($graph,
                                                    cmp => $options{'cmp'});
    ### @vertices_by_depth
    my @column;
    foreach my $aref (reverse @vertices_by_depth) {
      my $c = 0;
      foreach my $v (@$aref) {
        my @children = Graph_vertex_children($graph,$v);
        if (@children) {
          ### vertex: "$v children @children"
          $c = max($c,
                   ceil( sum(map {$column[$_] + (length($_)+1)/2} @children) / scalar(@children)
                         - (length($v)+1)/2 ));
        }
        $column[$v] = $c;
        $c += length($v) + 1;
        $c = max($c, map {$column[$_] + length($_)+1} Graph_tree_descendents($graph, $v));
      }
    }

    my $total_column = max(map {($column[$_]||0)+length($_)} 0 .. $#column) + 3;
    foreach my $aref (@vertices_by_depth) {
      my $c = 0;
      ### columns: map {$column[$_]} @$aref
      foreach my $v (@$aref) {
        while ($c < $column[$v]) {
          print " ";
          $c++;
        }
        print $v," ";
        $c += length($v)+1;
      }
      while ($c < $total_column) {
        print " ";
        $c++;
      }
      my $count = @$aref;
      print "count $count\n";
    }
    return;
  }
}
# use Smart::Comments;
sub Graph_tree_layout {
  my ($graph, %options) = @_;
  my $v = $options{'v'} // Graph_tree_root($graph);
  my $x = $options{'x'} || 0;
  my $y = $options{'y'} || 0;
  my $filled = $options{'filled'} // [];

  my @children = Graph_vertex_children($graph,$v);
  my @heights = map {Graph_tree_height($graph,$_)} @children;
  my @order = sort {$heights[$b] <=> $heights[$a]} 0 .. $#children;

  my $h = (@children ? $heights[$order[0]]+1 : 0);
  ### $h
 Y: for (;;) {
    foreach my $i (0 .. $h) {
      if ($filled->[$x+$i]->[$y]) {
        $filled->[$x]->[$y] = 1;
        $y++;
        next Y;
      }
    }
    last;
  }
  ### place: "$v at $x,$y"
  Graph_set_xy_points($graph, $v => [$x,-$y]);
  $filled->[$x]->[$y] = 1;

  foreach my $i (@order) {
    Graph_tree_layout($graph, v=>$children[$i],
                      x=>$x+1, y=>$y++,
                      filled=>$filled);
  }
}
# no Smart::Comments;

#------------------------------------------------------------------------------

# vertices are coordinate strings "$x,$y" and edges along a square grid
# print an ascii form of the graph
#
sub Graph_xy_print {
  my ($graph) = @_;
  my @vertices = $graph->vertices;
  my @points = map {[split /,/]} @vertices;
  my @x = map {$_->[0]} @points;
  my @y = map {$_->[1]} @points;
  my $x_min = (@x ? min(@x) - 1 : 0);
  my $x_max = (@x ? max(@x) + 1 : 0);
  my $y_min = (@y ? min(@y) - 1 : 0);
  my $y_max = (@y ? max(@y) + 1 : 0);
  foreach my $y (reverse $y_min .. $y_max) {
    printf "%3s ", '';
    foreach my $x ($x_min .. $x_max) {
      my $from = "$x,$y";
      # vertical edge to above
      print $graph->has_edge($from, $x.",".($y+1)) ? "|   " : "    ";
    }
    print "\n";

    printf "%3d ", $y;
    foreach my $x ($x_min .. $x_max) {
      my $from = "$x,$y";
      # horizontal edge to next
      print $graph->has_vertex($from) ? "*" : " ";
      print $graph->has_edge($from, ($x+1).",".$y) ? "---" : "   ";
    }
    print "\n";
  }

  print " ";
  foreach my $x ($x_min .. $x_max) {
    printf "%4d", $x;
  }
  print "\n";
}

sub Graph_xy_print_triangular {
  my ($graph) = @_;
  my @vertices = $graph->vertices;
  my @points = map {[split /,/]} @vertices;
  my @x = map {$_->[0]} @points;
  my @y = map {$_->[1]} @points;
  my $x_min = (@x ? min(@x) - 1 : 0);
  my $x_max = (@x ? max(@x) + 1 : 0);
  my $y_min = (@y ? min(@y) - 1 : 0);
  my $y_max = (@y ? max(@y) + 1 : 0);
  foreach my $y (reverse $y_min .. $y_max) {
    printf "%3s ", '';
    foreach my $x ($x_min .. $x_max) {
      my $from = "$x,$y";
      # vertical edge to above
      print $graph->has_edge($from, ($x  ).",".($y+1)) ? "|" : " ";
      print $graph->has_edge(($x).",".($y+1), ($x+1).",".($y)) ? "\\"
        : $graph->has_edge($from, ($x+1).",".($y+1)) ? "/" : " ";
    }
    print "\n";

    printf "%3d ", $y;
    foreach my $x ($x_min .. $x_max) {
      my $from = "$x,$y";
      # horizontal edge to next
      print $graph->has_vertex($from) ? "*"
        : $graph->has_edge(($x-1).",".$y, ($x+1).",".$y) ? "-"
        : " ";
      print $graph->has_edge(($x-1).",".$y, ($x+1).",".$y)
        || $graph->has_edge($from, ($x+1).",".$y)
        || $graph->has_edge($from, ($x+2).",".$y) ? "-" : " ";
    }
    print "\n";
  }

  print "       ", ($x_min&1 ? '  ' : '');
  for (my $x = $x_min+($x_min&1); $x <= $x_max; $x+=2) {
    printf "%4d", $x;
  }
  print "\n";
}

#------------------------------------------------------------------------------

our $HOG_directory = File::Spec->catdir(File::HomeDir->my_home, 'HOG');

# $coderef = make_tree_iterator_edge_aref()
# Return a function which iterates through trees in the form of edge arrayrefs.
# Each call to the function is
#     $edge_aref = $coderef->();
# returning an arrayref [ [1,2], [2,3], ... ] of a tree, or undef at end of
# iteration.
#
# Optional key/value parameters are
#     num_vertices_min => $integer \ min and max vertices in the trees
#     num_vertices_max => $integer /
#     degree_list      => arrayref [ 1, 2, 4 ]
#     degree_max       => $integer
#     degree_predicate => $coderef
#
sub make_tree_iterator_edge_aref {
  my %option = @_;
  require Graph::Graph6;

  my $degree_predicate_aref;
  if (defined (my $degree_list = $option{'degree_list'})) {
    my @degree_predicate_array;
    foreach my $degree (@$degree_list) {
      $degree_predicate_array[$degree] = 1;
    }
    $degree_predicate_aref = \@degree_predicate_array;
  } elsif (defined (my $degree_max = $option{'degree_max'})) {
    my @degree_predicate_array;
    foreach my $degree (1 .. $degree_max) {
      $degree_predicate_array[$degree] = 1;
    }
    $degree_predicate_aref = \@degree_predicate_array;
  }


  my $num_vertices= ($option{'num_vertices'}
                     // $option{'num_vertices_min'}
                     // 1);
  $num_vertices = max(1, $num_vertices);  # no trees of 0 vertices
  my $num_vertices_max = ($option{'num_vertices_max'}
                          // $num_vertices);
  $num_vertices--;

  my $fh;
  return sub {
    for (;;) {
      if (! $fh) {
        if (defined $num_vertices_max && $num_vertices >= $num_vertices_max) {
          return;
        }
        $num_vertices++;
        ### open: $num_vertices
        my $filename = File::Spec->catfile($HOG_directory,
                                           sprintf('trees%02d.g6',
                                                   $num_vertices));
        open $fh, '<', $filename
          or die "Cannot open $filename: $!";
      }

      my @edges;
      unless (Graph::Graph6::read_graph(fh => $fh,
                                        num_vertices_ref => \my $file_num_vertices,
                                        edge_aref => \@edges)) {
        ### EOF ...
        close $fh or die;
        undef $fh;
        next;
      }
      my $edge_aref = \@edges;
      if ($degree_predicate_aref
          && ! edge_aref_degree_check($edge_aref, $degree_predicate_aref)) {
        ### skip for degree_max ...
        next;
      }
      return $edge_aref;
    }
  };
}

# Return an iterator $itfunc to be called as
#     $edge_aref = $itfunc->()
# which iterates through all connected graphs.
# Parameters:
#   num_vertices      => integer
#   num_vertices_min  => integer
#   num_vertices_max  => integer
#   num_edges_min     => integer
#   num_edges_max     => integer
#   connected         => bool, default true
#
sub make_graph_iterator_edge_aref {
  my %option = @_;
  require Graph::Graph6;

  my $num_vertices = ($option{'num_vertices'}
                      // $option{'num_vertices_min'}
                      // 1);
  my $num_vertices_max = ($option{'num_vertices_max'}
                          // $option{'num_vertices'});

  my $num_edges_min = $option{'num_edges_min'};
  my $num_edges_max = $option{'num_edges_max'};
  my @geng_edges_option;
  if ($option{'verbose'}) {
    push @geng_edges_option, '-v';
  } else {
    push @geng_edges_option, '-q';
  }
  if ($option{'connected'} // 1) {
    push @geng_edges_option, '-c';
  }
  if (defined $num_edges_max || defined $num_edges_min) {
    if (! defined $num_edges_min) { $num_edges_min = 0; }
    if (! defined $num_edges_max) { $num_edges_max = '#'; }
    push @geng_edges_option, "$num_edges_min:$num_edges_max";
  }
  ### @geng_edges_option

  $num_vertices--;

  require IPC::Run;
  my $fh;
  return sub {
    for (;;) {
      if (! $fh) {
        if (defined $num_vertices_max && $num_vertices >= $num_vertices_max) {
          return;
        }
        $num_vertices++;
        ### open: $num_vertices
        IPC::Run::start(['nauty-geng',
                         # '-l',  # canonical
                         $num_vertices,
                         @geng_edges_option],
                        '<', File::Spec->devnull,
                        '|', ['sort'],
                        '>pipe', \*OUT);
        $fh = \*OUT;
      }

      my @edges;
      unless (Graph::Graph6::read_graph(fh => $fh,
                                        num_vertices_ref => \my $file_num_vertices,
                                        edge_aref => \@edges)) {
        ### EOF ...
        close $fh or die;
        undef $fh;
        next;
      }
      my $edge_aref = \@edges;
      return $edge_aref;
    }
  };
}

# Return true if the degrees of the nodes in $edge_aref all have
# arrayref $degree_predicate_aref->[$degree] true.
#
sub edge_aref_degree_check {
  my ($edge_aref, $degree_predicate_aref) = @_;
  my @vertex_degree;
  foreach my $edge (@$edge_aref) {
    my ($from, $to) = @$edge;
    $vertex_degree[$from]++;
    $vertex_degree[$to]++;
  }
  foreach my $degree (@vertex_degree) {
    if (! $degree_predicate_aref->[$degree]) {
      return 0;
    }
  }
  return 1;
}

# $edge_aref is an arrayref [ [from,to], [from,to], ... ]
# where each vertex is integer 0 upwards
# Return a list (degree, degree, ...) of degree of each vertex
sub edge_aref_degrees {
  my ($edge_aref) = @_;
  ### edge_aref_degrees: $edge_aref
  my @vertex_degree;
  foreach my $edge (@$edge_aref) {
    my ($from, $to) = @$edge;
    $vertex_degree[$from]++;
    $vertex_degree[$to]++;
  }
  return map {$_//0} @vertex_degree;
}
# $edge_aref is an arrayref [ [from,to], [from,to], ... ]
# where each vertex is integer 0 upwards
# Return a list (degree, degree, ...) of distinct vertex degrees which occur
# in the graph.
sub edge_aref_degrees_distinct {
  my ($edge_aref) = @_;
  my @vertex_degree = edge_aref_degrees($edge_aref);
  my %seen;
  @vertex_degree = grep {! $seen{$_}++} @vertex_degree;
  return sort {$a<=>$b} @vertex_degree;
}

# Trees by search.
# {
#   my @parent = (undef, -1);
#   my $v = 1;
#   for (;;) {
#     my $p = ++$parent[$v];
#     ### at: "$v consider new parent $p"
#     if ($p >= $v) {
#       ### backtrack ...
#       $v--;
#       if ($v < 1) { last; }
#       $p = $parent[$v];  # unparent this preceding v
#       $num_children[$p]--;
#       next;
#     }
#
#     if ($num_children[$p] >= ($p==0 ? 4 : 3)) {
#       next;
#     }
#
#     $num_vertices = $v;
#     $process_tree->();
#
#     if ($v < $num_vertices_limit) {
#       # descend
#       $num_children[$p]++;
#       # $num_children[$p] == grep {$_==$p} @parent[1..$v] or die;
#       $num_children[$v] = 0;
#       $v++;
#       $parent[$v] = -1;
#       $num_vertices = $v;
#     }
#   }
# }

# Tree iterator by parent.
# {
#   @parent = (undef);
#   @num_children = (0);
#   my $v = 0;
#   for (;;) {
#     $num_children[$v]++;
#     my $new_v = $v + $num_children[$v];
#     ### at: "$v consider new children $num_children[$v]"
#
#     if ($num_children[$v] > ($v==0 ? 4 : 3)
#         || $new_v > $num_vertices_limit) {
#       ### backtrack ...
#       $v = $parent[$v] // last;
#       next;
#     }
#
#     # add children
#     foreach my $i (1 .. $num_children[$v]) {
#       my $c = $v + $i;
#       $parent[$c] = $v;
#       $num_children[$c] = 0;
#     }
#     $v = $new_v-1;
#     $num_vertices = $v;
#     $process_tree->();
#   }
# }



#------------------------------------------------------------------------------

use constant::defer hog_directory => sub {
  require File::Spec;
  require File::HomeDir;
  File::Spec->catdir(File::HomeDir->my_home, 'HOG');
};
use constant::defer hog_all_filename => sub {
  require File::Spec;
  File::Spec->catdir(hog_directory, 'all.g6');
};
use constant::defer hog_mmap_ref => sub {
  require File::Map;
  my $mmap;
  File::Map::map_file ($mmap, hog_all_filename());
  return \$mmap;
};

# $str is a string of graph6 in canonical labelling.
# Return true if it is in the House of Graphs, based on grepping the all.g6
# file (hog_all_filename()).
sub hog_grep {
  my ($str) = @_;
  require File::Slurp;
  ### hog_grep(): $str
  $str =~ s/\n$//;
  my $mmap_ref = hog_mmap_ref();
  if ($$mmap_ref =~ /^\Q$str\E$/m) {
    $str =~ s/\n+$//g;
    foreach my $filename (glob(File::Spec->catfile(hog_directory(), 'graph_*.g6'))) {
      if (defined (my $file_str = File::Slurp::read_file($filename, err_mode=>'quiet'))) {
        $file_str =~ s/\n+$//g;
        if ($file_str eq $str) {
          if ($filename =~ m{graph_([^/]*)\.g6$}) {
            return $1;
          } else {
            return $filename;
          }
        }
      }
    }
    return -1;
  }
}

# $num is a House of Graphs graph ID number.
# Return the local filename for its graph6.
# There's no check whether the file actually exists.
sub hog_num_to_filename {
  my ($num) = @_;
  require File::Spec;
  File::Spec->catfile(hog_directory(), "graph_$num.g6");
}

sub hog_compare {
  my ($id, $g6_str) = @_;
  require File::Slurp;
  my $filename = hog_num_to_filename($id);
  my $file_str = File::Slurp::read_file($filename);
  my $canon_g6_str = graph6_str_to_canonical($g6_str);
  my $canon_file_str = graph6_str_to_canonical($file_str);
  if ($g6_str ne $file_str) {
    print "id=$id wrong\n";
    print "string $g6_str";
    print "file   $file_str";
    print "canon string $canon_g6_str";
    print "canon file   $canon_file_str";
    croak "wrong";
  }
}
sub hog_id_to_url {
  my ($id) = @_;
  # ENHANCE-ME: maybe escape against some bad id string
  return "https://hog.grinvin.org/ViewGraphInfo.action?id=$id";
}

# hog_searches_html($graph,$graph,...)
# Create a /tmp/USERNAME/hog-searches.html of forms to search hog for each
# $graph.  Each $graph can be either Graph.pm or Graph::Easy.
#
# The hog-searches.html is a bit rough, and requires you select the 0.g6,
# 1.g6, etc file to search for.  The HOG server expects a file upload, and
# don't think can induce a browser to do a file-like POST other than by
# selecting a file.  Some Perl code POST could do it easily, but the idea is
# to present a range of searches and you might only do a few.
#
sub hog_searches_html {
  my @graphs = @_;
  ### hog_searches_html() ...

  require HTML::Entities;
  require File::Spec;
  require File::Temp;
  require POSIX;
  my $dir = File::Spec->catdir('/tmp', POSIX::cuserid());
  mkdir $dir;
  my $html_filename = File::Spec->catfile($dir, 'hog-searches.html');

  my $hog_url = 'https://hog.grinvin.org';
  # $hog_url = 'http://localhost:10000';    # for testing
  my @names;

  open my $h, '>', $html_filename or die;
  print $h <<'HERE';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<body>
HERE

  my %seen_canonical;
  foreach my $i (0 .. $#graphs) {
    my $graph = $graphs[$i];
    ### graph: "$graph"
    if (! ref $graph) {
      ### convert graph6 string ...
      $graph = Graph_from_graph6_str($graph);
    } elsif (! blessed($graph)) {
      ### convert edge_aref ...
      if (ref $graph) {
        $graph = edge_aref_to_Graph_Easy($graph);
      } else {
        $graph = Graph_from_graph6_str($graph);
      }
    }
    my $graph6_filename = File::Spec->catfile($dir, "$i.g6");
    my $png_fh          = File::Temp->new;
    my $png_filename    = $png_fh->filename;
    ### $graph6_filename

    if ($graph->isa('Graph::Easy')) {
      require Graph::Easy::As_graph6;
      require File::Slurp;
      File::Slurp::write_file($graph6_filename,$graph->as_graph6);
    } else {
      require Graph::Writer::Graph6;
      my $writer = Graph::Writer::Graph6->new;
      $writer->write_graph($graph, $graph6_filename);
    }
    my $graph6_size = (-s $graph6_filename) - 1;
    require File::Slurp;
    my $graph6_str = File::Slurp::read_file($graph6_filename);

    my $num_vertices = $graph->vertices;
    my $num_edges    = $graph->edges;
    my $name;
    my $flow = 'south';
    my $vertex_name_type;
    if ($graph->isa('Graph::Easy')) {
      $name = $graph->get_attribute('label');
      # FIXME: custom attributes?
      # $vertex_name_type = $graph->get_attribute('graph','vertex_name_type');
    } else {
      $name = $graph->get_graph_attribute('name');
      $vertex_name_type = $graph->get_graph_attribute('vertex_name_type');
      $flow = $graph->get_graph_attribute('flow') // $flow;
    }
    $vertex_name_type //= '';
    $name //= '';
    $names[$i] = $name;

    my $graph6_canonical = graph6_str_to_canonical($graph6_str);
    my $canonical = $graph6_canonical;
    if (length($canonical) > 30) {
      $canonical = '';
    } else {
      $canonical = "<br> canonical "
        . HTML::Entities::encode_entities($canonical);
    }

    if (defined(my $prev = $seen_canonical{$graph6_canonical})) {
      print "g$i $name\n  REPEAT  g$prev $names[$prev]\n";
      print $h "<br> repeat of $seen_canonical{$graph6_canonical} ",
        HTML::Entities::encode_entities($names[$prev]),
          "\n";
    } else {
      $seen_canonical{$graph6_canonical} = $i;
    }

    my $got = '';
    if (my $num = hog_grep($graph6_canonical)) {
      my $str = $graph6_canonical;
      $str =~ s/\n+$//;
      print "g$i HOG got $str  n=$num_vertices",
        ($num eq '-1' ? '' : " id=$num"),
        "    $name\n";

      if ($num eq '-1') {
        my $filename = HTML::Entities::encode_entities(hog_all_filename());
        $got = "<br> got in $filename\n";
      } else {
        my $url = hog_id_to_url($num);
        $num = HTML::Entities::encode_entities($num);
        $got = "<br> got <a href=\"$url\">HOG id $num</a>\n";
      }
    }

    print $h <<"HERE";
<hr width="100%">
<p>
  <a href="file://$graph6_filename">$graph6_filename</a>
  $graph6_size bytes,
  $num_vertices vertices,
  $num_edges edges
  $name$canonical$got
HERE

    if ($num_vertices == 0) {
      print $h "empty\n";
    }
    print $h <<"HERE";
  <FORM name="DoSearchGraphFromFile" id="DoSearchGraphFromFile"
        action="$hog_url/DoSearchGraphFromFile.action"
        enctype="multipart/form-data" method="post">
    <INPUT name="graphFormatName" type="hidden" value="Graph6">
    <INPUT name="upload" id="DoSearchGraphFromFile_upload"
           type="file"
           value="$graph6_filename">
    <INPUT id="DoSearchGraphFromFile_0" type="submit" value="Search graph">
  </FORM>
HERE

    if ($num_vertices <= 60) {
      my $is_xy = $graph->isa('Graph')
        && ($graph->get_graph_attribute('vertex_name_type_xy')
            || $graph->get_graph_attribute('xy')
            || do {
              my $type = $graph->get_graph_attribute('vertex_name_type');
              defined $type && $type =~ /^xy/ }
            || do {
              my ($v) = $graph->vertices;
              defined $v && defined($graph->get_vertex_attribute($v,'x')) });
      if ($is_xy || 1) {
        ### write with graphviz2 neato ...
        my $graphviz2 = Graph_to_GraphViz2($graphs[$i]);
        $graphviz2->run(format => 'png',
                        output_file=>$png_filename,
                        driver => 'neato');
        ### dot_input: $graphviz2->dot_input
      } elsif (1) {
        ### write with graphviz2 dot ...
        my $graphviz2 = Graph_to_GraphViz2($graphs[$i]);
        $graphviz2->run(format => 'png',
                        output_file=>$png_filename);
      } else {
        my $easy = $graph;
        if ($graph->isa('Graph')) {
          ### Graph num nodes ...
          my $graph = $graph->copy;
          foreach my $v ($graph->vertices) {
            $graph->delete_vertex_attribute($v,'xy');
          }
          require Graph::Convert;
          $easy = Graph::Convert->as_graph_easy($graph);
        }
        # Graph_Easy_blank_labels($easy);
        foreach my $v (1,0) {
          if (defined($easy->node($v))) {
            $easy->set_attribute('root',$v);  # for as_graphviz()
            $easy->set_attribute('flow',$flow);  # for as_graphviz()
          }
        }
        ### Graph-Easy num nodes: scalar($easy->nodes)
        $easy->set_attribute('x-dot-start','1');
        my $graphviz = $easy->as_graphviz;
        # $graphviz =~ s/node \[/node [\n    height=.08,\n    width=.08,\n    fixedsize=1,/;
        # print $graphviz;

        require IPC::Run;
        IPC::Run::run(['dot','-Tpng',
                      ],
                      '<',\$graphviz, '>',$png_filename);
        # IPC::Run::run(['neato','-Tpng'], '<',\$graphviz, '>',$png_filename);
        # IPC::Run::run(['fdp','-Tpng'], '<',\$graphviz, '>',$png_filename);
        # print $easy->as_ascii;
      }

      require File::Slurp;
      my $png = File::Slurp::read_file($png_filename);

      require URI::data;
      my $png_uri = URI->new("data:");
      $png_uri->data($png);
      $png_uri->media_type('image/png');
      # my  = URI::data->new($png,'image/png');

      print $h qq{<img src="$png_uri">\n};
    }
  }

  print $h <<'HERE';
  </body>
</html>
HERE
  close $h or die;

  print scalar(@graphs)," graphs\n";
  print "mozilla file://$html_filename >/dev/null 2>&1 &\n";
}

# blank out all labels of a Graph::Easy
sub Graph_Easy_blank_labels {
  my ($easy) = @_;
  foreach my $node ($easy->nodes) {
    $node->set_attribute(label => ' ');
  }
}

sub edge_aref_to_Graph_Easy {
  my ($edge_aref) = @_;
  ### $edge_aref
  require Graph::Easy;
  my $easy = Graph::Easy->new (undirected => 1);
  foreach my $edge (@$edge_aref) {
    scalar(@$edge) == 2 or die "bad edge_aref";
    my ($from, $to) = @$edge;
    ($from =~ /^[0-9]+$/ && $to =~ /^[0-9]+$/) or die "bad edge_aref";
    $easy->add_edge($from,$to);
  }
  return $easy;
}
sub edge_aref_to_Graph {
  my ($edge_aref) = @_;
  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->add_edges(@$edge_aref);
  return $graph;
}

sub edge_aref_string {
  my ($edge_aref) = @_;
  return join(',', map{join('-',@$_)} @$edge_aref)
    . ' ['.scalar(@$edge_aref).' edges]';
}

# Create a file /tmp/USERNAME/hog-upload.html which is an upload of $graph.
# This uses the HOG add-a-graph by drawing.  Log-in first, then click Upload
# in hog-upload.html.
#
# The upload is an adjacency matrix and vertex locations.  These are the
# text fields in the HTML, but are likely to be too big to see anything
# useful.
# Vertex locations are from Graph_vertex_xy($graph, ...).
# The server draws straight-line edges between locations.

# hog-upload.html includes a simple png image so you can preview how it
# ought to come out.  The Upload click goes to the usual HOG page to enter a
# name and comment.  You don't see the image in HOG until after that, but if
# it goes badly wrong you can always delete the graph.
#
sub hog_upload_html {
  my ($graph, %options) = @_;
  require POSIX;
  require File::Spec;
  require File::Temp;
  my $dir = File::Spec->catdir('/tmp', POSIX::cuserid());
  mkdir $dir;
  my $html_filename   = File::Spec->catfile($dir, 'hog-upload.html');
  # my $png_filename  = File::Spec->catfile($dir, 'hog-upload.png');
  my $png_fh          = File::Temp->new;
  my $png_filename    = $png_fh->filename;
  my $hog_url = 'https://hog.grinvin.org';
  # $hog_url = 'http://localhost';  # for testing

  my @vertices = MyGraphs::Graph_sorted_vertices($graph);
  my $name = $graph->get_graph_attribute('name') // '';
  my $num_vertices = scalar(@vertices);
  my $num_edges = $graph->edges;
  print "graph $name\n";
  print "$num_vertices vertices, $num_edges edges\n";

  my @points = map { my ($x,$y) = MyGraphs::Graph_vertex_xy($graph,$_)
                       or croak("no X,Y coordinates for vertex ",$_);
                     [$x,$y]
                   } @vertices;
  ### @points

  if (my $a = $options{'rotate_degrees'}) {
    $a = Math::Trig::deg2rad($a);
    my $s = sin($a);
    my $c = cos($a);
    @points = map {
      [ $_->[0] * $c - $_->[1] * $s,
        $_->[0] * $s + $_->[1] * $c ]
    } @points;
  }

  my @x = map {$_->[0]} @points;
  my @y = map {$_->[1]} @points;
  my $size = max( max(@x)-min(@x), max(@y)-min(@y) );

  require Geometry::AffineTransform;
  my $affine = Geometry::AffineTransform->new;
  $affine->translate( -(max(@x)+min(@x))/2, -(max(@y)+min(@y))/2 );
  $affine->scale(1/$size, -1/$size);  # Y down the page
  $affine->scale(380, 380);
  $affine->translate(200, 200);
  @points = map {[$affine->transform(@$_)]} @points;
  @points = map {[map {POSIX::round($_)} @$_]} @points;
  @x = map {$_->[0]} @points;
  @y = map {$_->[1]} @points;
  print "transformed x ",min(@x)," to ",max(@x),
    "  y ",min(@y)," to ",max(@y),"\n";

  require Image::Base::GD;
  my $image = Image::Base::GD->new (-width => 400, -height => 400);
  $image->rectangle(0,0, 400,400, 'white', 1);
  $image->rectangle(0,0, 399,399, 'blue');

  foreach my $from (0 .. $#vertices) {
    foreach my $to (0 .. $#vertices) {
      if ($graph->has_edge($vertices[$from], $vertices[$to])) {
        $image->line(@{$points[$from]}, @{$points[$to]}, 'red');
      }
    }
  }
  foreach my $from (0 .. $#vertices) {
    my ($x,$y) = @{$points[$from]};
    $image->ellipse($x-1,$y-1, $x+1,$y+1, 'black');
  }
  $image->save($png_filename);
  require File::Slurp;
  my $png = File::Slurp::read_file($png_filename);

  require URI::data;
  my $png_uri = URI->new("data:");
  $png_uri->data($png);
  $png_uri->media_type('image/png');
  # my  = URI::data->new($png,'image/png');

  # stringize the points
  @points = map {join('-',@$_).';'} @points;
  ### @points
  unless (list_is_all_distinct_eq(@points)) {
    die "oops, some point coordinates have rounded together";
  }

  my $coordinateString = join('',@points);
  ### $coordinateString

  # 0100000000000000%0D%0A
  # 1010000000000000%0D%0A
  # 0101000000000000%0D%0A
  # 0010100000000000%0D%0A
  # 0001010000000000%0D%0A
  # 0000101010001000%0D%0A
  # 0000010100000000%0D%0A
  # 0000001010000000%0D%0A
  # 0000010100000000%0D%0A
  # 0000000000101000%0D%0A
  # 0000000001010000%0D%0A
  # 0000000000100001%0D%0A
  # 0000010001000000%0D%0A
  # 0000000000000010%0D%0A
  # 0000000000000101%0D%0A
  # 0000000000010010
  my @adjacencies = map {
    my $from = $_;
    join('', map {$graph->has_edge($from,$_) ? 1 : 0} @vertices)
  } @vertices;
  ### @adjacencies

  my $adjacencyString = join("\r\n",@adjacencies);

  require HTML::Entities;
  my @names;
  $name = HTML::Entities::encode_entities($name);
  my $upsize = length($adjacencyString) + length($coordinateString) + 20;
  print "upload size $upsize bytes\n";

  open my $h, '>', $html_filename or die;
  print $h <<"HERE";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<body>
Upload $name
<br>
$num_vertices vertices, $num_edges edges, size $upsize bytes
<br>
<form action="$hog_url/DoUploadGraph.action" method="POST">
<textarea name="adjacencyString" value="">$adjacencyString</textarea>
<br>
<input name="coordinateString" value="$coordinateString">
<br>
<input type=submit value="Upload">
</form>
<p>
<img width=400 height=400 src="$png_uri">
</body>
</html>
HERE
  close $h or die;

  print "mozilla file://$html_filename >/dev/null 2>&1 &\n";
}

# Return true of all arguments are different, as compared by "eq".
sub list_is_all_distinct_eq {
  my %seen;
  foreach (@_) {
    if ($seen{$_}++) {
      return 0;
    }
  }
  return 1;
}


#------------------------------------------------------------------------------
# nauty bits

sub graph6_view {
  my ($g6_str, %options) = @_;
  my $graph = Graph_from_graph6_str($g6_str);
  my $name = $options{'name'};
  if (! defined $name || $name eq '') {
    my $num_vertices = $graph->vertices;
    my $num_edges    = $graph->edges;
    $graph->set_graph_attribute
      (name => "$num_vertices vertices, $num_edges edges");
  }
  Graph_view($graph);
}
sub graph6_str_to_canonical {
  my ($g6_str) = @_;
  ### graph6_str_to_canonical(): $g6_str

  # num_vertices == 0 is already canonical and nauty-labelg doesn't like to
  # crunch that
  if ($g6_str =~ /^\?/) {
    return $g6_str;
  }

  unless ($g6_str =~ /\n$/) { $g6_str .= "\n"; }
  if ($g6_str =~ /\n.*\n/s) { croak "multiple newlines in g6 string"; }

  my $canonical;
  my $err;
  require IPC::Run;
  if (! IPC::Run::run(['nauty-labelg',
                       '-g',  # graph6 output
                       # '-i2',
                      ],
                      '<',\$g6_str,
                      '>',\$canonical,
                      '2>',\$err)) {
    die "nauty-labelg error: ",$canonical,$err;
  }
  return $canonical;
}

sub Graph_to_sparse6_str {
  my ($graph) = @_;
  require Graph::Writer::Sparse6;
  my $writer = Graph::Writer::Sparse6->new;
  open my $fh, '>', \my $str or die;
  $writer->write_graph($graph, $fh);
  return $str;
}
sub Graph_to_graph6_str {
  my ($graph, %options) = @_;
  require Graph::Writer::Graph6;
  my $writer = Graph::Writer::Graph6->new
    (format => ($options{'format'}||'graph6'));
  open my $fh, '>', \my $str or die;
  $writer->write_graph($graph, $fh);
  return $str;
}

# $str is a graph6 or sparse6 string
sub Graph_from_graph6_str {
  my ($str) = @_;
  require Graph::Reader::Graph6;
  my $reader = Graph::Reader::Graph6->new;
  open my $fh, '<', \$str or die;
  return $reader->read_graph($fh);
}
# $filename is a file containing graph6 or sparse6
sub Graph_from_graph6_filename {
  my ($filename) = @_;
  require Graph::Reader::Graph6;
  my $reader = Graph::Reader::Graph6->new;
  open my $fh, '<', $filename or die 'Cannot open ',$filename,': ',$!;
  return $reader->read_graph($fh);
}

# return true if Graph.pm graphs $g1 and $g2 are isomorphic
sub Graph_is_isomorphic {
  my ($g1, $g2) = @_;
  my $g1_str = graph6_str_to_canonical(Graph_to_graph6_str($g1));
  my $g2_str = graph6_str_to_canonical(Graph_to_graph6_str($g2));
  return $g1_str eq $g2_str;
}

sub Graph_from_edge_aref {
  my ($edge_aref, %options) = @_;
  my $num_vertices = delete $options{'num_vertices'};
  my $graph = Graph->new (undirected => 1);
  $graph->add_vertices (0 .. ($num_vertices||0)-1);
  foreach my $edge (@$edge_aref) {
    scalar(@$edge) == 2 or die "bad edge_aref";
    my ($from, $to) = @$edge;
    ($from =~ /^[0-9]+$/ && $to =~ /^[0-9]+$/) or die "bad edge_aref";
    $graph->add_edge($from,$to);
  }
  return $graph;
}

sub Graph_from_vpar {
  my ($vpar, @options) = @_;
  require Graph;
  my $graph = Graph->new (@options);
  $graph->add_vertices(1 .. $#$vpar);
  foreach my $v (1 .. $#$vpar) {
    if ($vpar->[$v]) {
      $graph->add_edge ($v, $vpar->[$v]);
    } else {
      $graph->set_graph_attribute('root',$v);
    }
  }
  if ($graph->is_directed) {
    $graph->set_graph_attribute('flow','north');
  }
  return $graph;
}

sub Graph_to_vpar {
  my ($graph, $root) = @_;
  $root //= Graph_tree_root($graph);
  ### Graph_to_vpar() ...
  ### $root
  my @vertices = sort $graph->vertices;
  my @vpar = (undef, (0) x scalar(@vertices));
  unshift @vertices, undef;
  ### @vertices
  my %vertex_to_v;
  foreach my $v (1 .. $#vertices) { $vertex_to_v{$vertices[$v]} = $v; }
  my %seen;
  $vpar[$vertex_to_v{$root}] = 0;
  $seen{$root} = 1;
  my @pending = ($root);
  while (@pending) {
    my $vertex = pop @pending;
    my $v = $vertex_to_v{$vertex};
    ### vertex: "$vertex  v=$v"
    my @neighbours = $graph->neighbours($vertex);
    ### @neighbours
    my $p = 0;
    $seen{$vertex} = 1;
    $vpar[$v] = 0;
    foreach my $neighbour (@neighbours) {
      if ($seen{$neighbour}) {
        $p = $vertex_to_v{$neighbour};
        $vpar[$v] = $p;
        ### set: "$v parent $p"
      } else {
        push @pending, $neighbour;
      }
    }
  }
  ### @vpar
  return \@vpar;
}
sub Graph_vpar_str {
  my ($graph) = @_;
  my $vpar = Graph_to_vpar($graph);
  my $str = "[";
  foreach my $v (1 .. $#$vpar) {
    $str .= ($vpar->[$v] // 'undef');
    if ($v != $#$vpar) { $str .= ","; }
  }
  $str .= "]";
}
sub Graph_print_vpar {
  my ($graph) = @_;
  my $vpar = Graph_to_vpar($graph);
  print "[";
  foreach my $v (1 .. $#$vpar) {
    print $vpar->[$v] // 'undef';
    if ($v != $#$vpar) { print ","; }
  }
  print "]\n";
}

# synchronous => 1, wait for viewer to exit before returning.
sub vpar_view {
  my ($vpar, %options) = @_;
  ### Graph_view(): %options
  my $graphviz2 = vpar_to_GraphViz2($vpar, %options);
  GraphViz2_view ($graphviz2, %options);
}
sub vpar_name {
  my ($vpar) = @_;
  my $str = 'N='.$#$vpar.' vpar';
  my $sep = ' ';
  foreach my $i (1..$#$vpar) {
    $str .= $sep;
    if (length($str) >= 45) {
      $str .= '...';
      return $str;
    }
    $str .= $vpar->[$i];
    $sep = ',';
  }
  return $str;
}
sub vpar_to_GraphViz2 {
  my ($vpar, %options) = @_;
  ### vpar_to_GraphViz2(): %options
  require GraphViz2;

  my $name = $options{'name'} // vpar_name($vpar);
  my $flow = ($options{'flow'} // 'up');
  my $graphviz2 = GraphViz2->new
    (global => { directed => 1 },
     graph  => { label    => $name,
                 rankdir  => ($flow eq 'down' ? 'TB'
                              : $flow eq 'up' ? 'BT'
                              : $flow),
                 ordering => 'out',
               },
     node => { margin => 0,  # cf default 0.11,0.055
             },
    );

  foreach my $v (1 .. $#$vpar) {
    $graphviz2->add_node(name => $v,
                         margin => '0.04,0.03',  # cf default 0.11,0.055
                         height => '0.1',  # inches, minimum
                         width  => '0.1',  # inches, minimum
                        );
  }
  foreach my $from (1 .. $#$vpar) {
    if (my $to = $vpar->[$from]) {
      $graphviz2->add_edge(from => $from, to => $to);
    }
  }

  # roots in cluster at same rank so aligned horizontally
  $graphviz2->push_subgraph (subgraph => {rank => 'same'});
  foreach my $v (1 .. $#$vpar) {
    unless ($vpar->[$v]) {
      $graphviz2->add_node(name => $v);
    }
  }
  $graphviz2->pop_subgraph;
  return $graphviz2;
}


#------------------------------------------------------------------------------
# triangles

# ($a,$b,$c) are vertices of a triangle in $graph.
#      a
#     / \
#    b---c
# Return true if this is an even triangle.  For an even triangle every other
# vertex in the graph has an edge going to an even number of the vertices
# a,b,c.  This means either no edges to them, or edges to exactly 2 of them.
#
sub Graph_triangle_is_even {
  my ($graph, $a,$b,$c) = @_;
  ### Graph_triangle_is_even(): "$a $b $c"
  foreach my $v ($graph->vertices) {
    next if $v eq $a || $v eq $b || $v eq $c;
    my $count = (($graph->has_edge($v,$a) ? 1 : 0)
                 + ($graph->has_edge($v,$b) ? 1 : 0)
                 + ($graph->has_edge($v,$c) ? 1 : 0));
    ### count: "$v is $count"
    unless ($count == 0 || $count == 2) {
      ### triangle odd ...
      return 0;
    }
  }
  ### triangle even ...
  return 1;
}

# $graph is a Graph.pm.
# Call $stop = $callback->($a,$b,$c) for each triangle in $graph.
# If the return $stop is true then stop the search.
# The return is the $stop value, or undef at end of search.
#
#      c
#     / \
#    a---b
#
# Triangles are found one way only, so if a,b,c then no calls also for
# permutations like b,a,c.  It's unspecified exactly which vertices are the
# $a,$b,$c in the callback (though the current code has then in ascending
# alphabetical order).
#
sub Graph_triangle_search {
  my ($graph, $callback) = @_;
  foreach my $a ($graph->vertices) {
    my @a_neighbours = sort $graph->neighbours($a);

    foreach my $bi (0 .. $#a_neighbours-2) {
      my $b = $a_neighbours[$bi];
      next if $b lt $a;

      foreach my $ci ($bi+1 .. $#a_neighbours-1) {
        my $c = $a_neighbours[$ci];
        if ($graph->has_edge($b,$c)) {
          if (my $stop = $callback->($a,$b,$c)) {
            return $stop;
          }
        }
      }
    }
  }
  return undef;
}

# $graph is a Graph.pm.
# ($a,$b,$c) = Graph_find_triangle($graph);
# Return a list of vertices which are a triangle within $graph.
# If no triangles then return an empty list;
#      c
#     / \
#    a---b
sub Graph_find_triangle {
  my ($graph) = @_;
  my @ret;
  Graph_triangle_search($graph, sub {@ret = @_});
  return @ret;
}

# $graph is a Graph.pm.
# Return true if $graph contains a triangle.
sub Graph_has_triangle {
  my ($graph) = @_;
  return Graph_triangle_search($graph, sub {1});
}

# $graph is a Graph.pm.
# Return the number of triangles in $graph.
sub Graph_triangle_count {
  my ($graph) = @_;
  my $count = 0;
  Graph_triangle_search($graph, sub { $count++; return 0});
  return $count;
}


#------------------------------------------------------------------------------
# Claws

# $graph is a Graph.pm.
# Call $stop = $callback->($a,$b,$c,$d) for each claw in $graph.
# $a is the centre.
# If the return $stop is true then stop the search.
# The return is the $stop value, or undef at end of search.
#      b
#     /
#    a--c
#     \
#      d
sub Graph_claw_search {
  my ($graph, $callback) = @_;
  foreach my $a ($graph->vertices) {
    my @a_neighbours = $graph->neighbours($a);

    foreach my $bi (0 .. $#a_neighbours-2) {
      my $b = $a_neighbours[$bi];

      foreach my $ci ($bi+1 .. $#a_neighbours-1) {
        my $c = $a_neighbours[$ci];
        next if $graph->has_edge($b,$c);

        foreach my $di ($ci+1 .. $#a_neighbours) {
          my $d = $a_neighbours[$di];
          next if $graph->has_edge($b,$d) || $graph->has_edge($c,$d);

          if (my $stop = $callback->($a,$b,$c,$d)) {
            return $stop;
          }
        }
      }
    }
  }
  return undef;
}

# $graph is a Graph.pm.
# ($a,$b,$c,$d) = Graph_find_claw($graph);
# Return a list of vertices which are a claw (a 4-star) within $graph, as an
# induced subgraph.  $a is the centre.
# If no claws then return an empty list;
#      b
#     /
#    a--c
#     \
#      d
sub Graph_find_claw {
  my ($graph) = @_;
  my @ret;
  Graph_claw_search($graph, sub {@ret = @_});
  return @ret;
}

# $graph is a Graph.pm.
# Return true if $graph contains a claw (star-4) as an induced subgraph.
sub Graph_has_claw {
  my ($graph) = @_;
  return Graph_claw_search($graph, sub {1});
}

# $graph is a Graph.pm.
# Return the number of induced claws in $graph.
sub Graph_claw_count {
  my ($graph) = @_;
  my $count = 0;
  Graph_claw_search($graph, sub { $count++; return 0});
  return $count;
}

#------------------------------------------------------------------------------

# Return a list of how many vertices at depths 0 etc down from $root.
# The first width is depth=0 which is $root itself so width=1.
sub Graph_width_list {
  my ($graph, $root) = @_;
  my @widths;
  my %seen;
  my @pending = ($root);
  while (@pending) {
    push @widths, scalar(@pending);

    my @new_pending;
    foreach my $v (@pending) {
      $seen{$v} = 1;
      my @children = $graph->neighbours($v);
      @children = grep {! $seen{$_}} @children;
      push @new_pending, @children;
    }
    @pending = @new_pending;
  }
  return @widths;
}

# $graph is a Graph.pm.
# Return true if all vertices of $graph have same degree.
#
sub Graph_is_regular {
  my ($graph) = @_;
  my $degree;
  foreach my $v ($graph->vertices) {
    my $d = $graph->degree($v);
    $degree //= $d;
    if ($d != $degree) { return 0; }
  }
  return 1;
}

# $graph and $subgraph are Graph.pm objects.
# Return true if $subgraph is a subgraph of $graph.
# This is a check of graph structure.  The vertex names in the two can be
# different.
#
sub Graph_is_subgraph {
  my ($graph, $subgraph) = @_;
  my $num_vertices = $graph->vertices;
  my $subgraph_num_vertices = $subgraph->vertices;
  edge_aref_is_subgraph(edge_aref_from_Graph($graph),
                        edge_aref_from_Graph($subgraph),
                        num_vertices => $num_vertices,
                        subgraph_num_vertices => $subgraph_num_vertices);
}

sub edge_aref_from_Graph {
  my ($graph) = @_;
  ### edge_aref_from_Graph(): "$graph"
  my @vertices = sort $graph->vertices;
  my %vertices = map { $vertices[$_] => $_ } 0 .. $#vertices;
  my @edges = $graph->edges;
  return [ map { my ($from,$to) = @$_;
                 [ $vertices{$from},$vertices{$to} ]
               } @edges ];
}

sub Graph_is_induced_subgraph {
  my ($graph, $subgraph, %options) = @_;
  my @graph_vertices    = sort $graph->vertices;
  my @subgraph_vertices = sort $subgraph->vertices;
  ### @graph_vertices
  ### @subgraph_vertices

  my @ret;
  my @used = (0) x (scalar(@graph_vertices) + 1);
  my @map = (-1) x (scalar(@subgraph_vertices) + 1);
  my $pos = 0;
 OUTER: for (;;) {
    $used[$map[$pos]] = 0;
    ### undo use: "used=".join(',',@used)
    for (;;) {
      my $m = ++$map[$pos];
      ### $m
      if ($m > $#graph_vertices) {
        $pos--;
        ### backtrack to pos: $pos
        if ($pos < 0) {
          last OUTER;
        }
        next OUTER;
      }
      if (! $used[$m]) {
        $used[$m] = 1;
        last;
      }
      ### used ...
    }
    ### incremented: "pos=$pos map=".join(',',@map)."  used=".join(',',@used)

    if ($graph->vertex_degree($graph_vertices[$map[$pos]])
        < $subgraph->vertex_degree($subgraph_vertices[$pos])) {
      ### graph degree smaller than subgraph ...
      next;
    }

    foreach my $p (0 .. $pos-1) {
      ### consider: "pos=$pos p=$p graph $graph_vertices[$map[$p]] to $graph_vertices[$map[$pos]]  subgraph $subgraph_vertices[$p] to $subgraph_vertices[$pos]"
      my $gedge = !! $graph->has_edge   ($graph_vertices[$map[$p]],
                                         $graph_vertices[$map[$pos]]);
      my $sedge = !! $subgraph->has_edge($subgraph_vertices[$p],
                                         $subgraph_vertices[$pos]);
      if ($gedge != $sedge) {
        next OUTER;
      }
    }
    # good for this next vertex at $pos, descend
    if (++$pos > $#subgraph_vertices) {
      # print "found:\n";
      # foreach my $p (0 .. $#subgraph_vertices) {
      #   print "  $subgraph_vertices[$p] <-> $graph_vertices[$map[$p]]\n";
      # }

      if ($options{'all_maps'}) {
        push @ret, { map {$subgraph_vertices[$_] => $graph_vertices[$map[$_]]}
                     0 .. $#subgraph_vertices};
        ### new map: $ret[-1]
        $pos--;
      } else {
        return join(', ',
                    map {"$subgraph_vertices[$_]=$graph_vertices[$map[$_]]"}
                    0 .. $#subgraph_vertices);
      }
    }
    $map[$pos] = -1;
  }

  if ($options{'all_maps'}) {
    return @ret;
  } else {
    return 0;
  }
}

sub edge_aref_is_induced_subgraph {
  my ($edge_aref, $subgraph_edge_aref) = @_;

  if (@$edge_aref < @$subgraph_edge_aref) {
    return 0;
  }

  my @degree;
  my @neighbour;
  foreach my $edge (@$edge_aref) {
    $neighbour[$edge->[0]][$edge->[1]] = 1;
    $neighbour[$edge->[1]][$edge->[0]] = 1;
    $degree[$edge->[0]]++;
    $degree[$edge->[1]]++;
  }
  ### @degree

  my @subgraph_degree;
  my @subgraph_neighbour;
  foreach my $edge (@$subgraph_edge_aref) {
    $subgraph_neighbour[$edge->[0]][$edge->[1]] = 1;
    $subgraph_neighbour[$edge->[1]][$edge->[0]] = 1;
    $subgraph_degree[$edge->[0]]++;
    $subgraph_degree[$edge->[1]]++;
  }
  ### @subgraph_degree

  {
    my @degree_sorted = sort {$b<=>$a} @degree;   # descending
    my @subgraph_degree_sorted = sort {$b<=>$a} @subgraph_degree;
    foreach my $i (0 .. $#subgraph_degree_sorted) {
      if ($subgraph_degree_sorted[$i] > $degree_sorted[$i]) {
        return 0;
      }
    }
  }

  my $num_vertices          = scalar(@neighbour);
  my $subgraph_num_vertices = scalar(@subgraph_neighbour);

  my @used = (0) x ($num_vertices + 1);
  my @map = (-1) x ($subgraph_num_vertices + 1);
  my $pos = 0;
 OUTER: for (;;) {
    $used[$map[$pos]] = 0;
    ### undo use: "used=".join(',',@used)
    for (;;) {
      my $m = ++$map[$pos];
      ### $m
      if ($m >= $num_vertices) {
        $pos--;
        ### backtrack to pos: $pos
        if ($pos < 0) {
          return 0;
        }
        next OUTER;
      }
      if (! $used[$m]) {
        $used[$m] = 1;
        last;
      }
      ### used ...
    }
    ### incremented: "pos=$pos map=".join(',',@map)."  used=".join(',',@used)

    if ($degree[$map[$pos]] < $subgraph_degree[$pos]) {
      ### graph degree smaller than subgraph ...
      next;
    }

    foreach my $p (0 .. $pos-1) {
      ### consider: "pos=$pos p=$p graph $map[$p] to $map[$pos]  subgraph $p to $pos"
      my $has_edge = ! $neighbour[$map[$p]][$map[$pos]];
      my $subgraph_has_edge = ! $subgraph_neighbour[$p][$pos];
      if ($has_edge != $subgraph_has_edge) {
        next OUTER;
      }
    }
    # good for this next vertex at $pos, descend
    if (++$pos >= $subgraph_num_vertices) {
      # print "found:\n";
      # foreach my $p (0 .. $subgraph_num_vertices-1) {
      #   print "  $p <-> $map[$p]\n";
      # }

      return join(', ', map {"$_=$map[$_]"} 0 .. $subgraph_num_vertices-1);
      # return 1;
    }
    $map[$pos] = -1;
  }
}

sub edge_aref_is_subgraph {
  my ($edge_aref, $subgraph_edge_aref, %option) = @_;
  ### edge_aref_is_subgraph() ...
  ### $edge_aref
  ### $subgraph_edge_aref

  my @degree;
  my @neighbour;
  foreach my $edge (@$edge_aref) {
    $neighbour[$edge->[0]][$edge->[1]] = 1;
    $neighbour[$edge->[1]][$edge->[0]] = 1;
    $degree[$edge->[0]]++;
    $degree[$edge->[1]]++;
  }
  ### @degree

  my @subgraph_degree;
  my @subgraph_neighbour;
  foreach my $edge (@$subgraph_edge_aref) {
    $subgraph_neighbour[$edge->[0]][$edge->[1]] = 1;
    $subgraph_neighbour[$edge->[1]][$edge->[0]] = 1;
    $subgraph_degree[$edge->[0]]++;
    $subgraph_degree[$edge->[1]]++;
  }
  ### @subgraph_degree

  if (defined (my $num_vertices = $option{'num_vertices'})) {
    $num_vertices >= @degree
      or croak "num_vertices option too small";
    $#degree    = $num_vertices - 1;
    $#neighbour = $num_vertices - 1;
  }
  if (defined (my $subgraph_num_vertices = $option{'subgraph_num_vertices'})) {
    $subgraph_num_vertices >= @subgraph_degree
      or croak "num_vertices option too small";
    $#subgraph_degree    = $subgraph_num_vertices - 1;
    $#subgraph_neighbour = $subgraph_num_vertices - 1;
  }

  if (@degree < @subgraph_degree) {
    ### graph fewer vertices than subgraph ...
    return 0;
  }

  my $num_vertices          = scalar(@neighbour);
  my $subgraph_num_vertices = scalar(@subgraph_neighbour);
  foreach my $i (0 .. $num_vertices-1) {
    $degree[$i] ||= 0;
  }
  foreach my $i (0 .. $subgraph_num_vertices-1) {
    $subgraph_degree[$i] ||= 0;
  }

  my @used = (0) x ($num_vertices + 1);
  my @map = (-1) x ($subgraph_num_vertices + 1);
  my $pos = 0;
 OUTER: for (;;) {
    $used[$map[$pos]] = 0;
    ### undo use: "used=".join(',',@used)
    for (;;) {
      my $m = ++$map[$pos];
      ### $m
      if ($m >= $num_vertices) {
        $pos--;
        ### backtrack to pos: $pos
        if ($pos < 0) {
          return 0;
        }
        next OUTER;
      }
      if (! $used[$m]) {
        $used[$m] = 1;
        last;
      }
      ### used ...
    }
    ### incremented: "pos=$pos map=".join(',',@map)."  used=".join(',',@used)

    if (($degree[$map[$pos]]||0) < ($subgraph_degree[$pos]||0)) {
      ### graph degree smaller than subgraph ...
      ### degree: $degree[$map[$pos]]
      ### subgraph degree: $subgraph_degree[$pos]
      next;
    }

    foreach my $p (0 .. $pos-1) {
      ### consider: "pos=$pos p=$p graph $map[$p] to $map[$pos]  subgraph $p to $pos"
      my $has_edge = $neighbour[$map[$p]][$map[$pos]];
      my $subgraph_has_edge = $subgraph_neighbour[$p][$pos];
      if ($subgraph_has_edge && ! $has_edge) {
        next OUTER;
      }
    }
    # good for this next vertex at $pos, descend
    if (++$pos >= $subgraph_num_vertices) {
      # print "found:\n";
      # foreach my $p (0 .. $subgraph_num_vertices-1) {
      #   print "  $p <-> $map[$p]\n";
      # }

      return join(', ', map {"$_=$map[$_]"} 0 .. $subgraph_num_vertices-1);
      # return 1;
    }
    $map[$pos] = -1;
  }
}

sub edge_aref_degrees_allow_subgraph {
  my ($edge_aref, $subgraph_edge_aref) = @_;

  if (@$edge_aref < @$subgraph_edge_aref) {
    return 0;
  }

  my @degree;
  foreach my $edge (@$edge_aref) {
    $degree[$edge->[0]]++;
    $degree[$edge->[1]]++;
  }
  ### @degree

  my @subgraph_degree;
  foreach my $edge (@$subgraph_edge_aref) {
    $subgraph_degree[$edge->[0]]++;
    $subgraph_degree[$edge->[1]]++;
  }
  ### @subgraph_degree

  @degree = sort {$b<=>$a} @degree;   # descending
  @subgraph_degree = sort {$b<=>$a} @subgraph_degree;
  foreach my $i (0 .. $#subgraph_degree) {
    if ($subgraph_degree[$i] > $degree[$i]) {
      return 0;
    }
  }
  return 1;
}

sub edge_aref_eccentricity {
  my ($edge_aref, $v) = @_;
  ### $v

  my $eccentricity = 0;
  my @edges = @$edge_aref;
  my @pending = ($v);
  while (@pending) {
    ### @edges
    ### @pending
    $eccentricity++;
    my @new_pending;
    foreach my $v (@pending) {
      @edges = grep {
        my ($from,$to) = @$_;
        my $keep = 1;
        if ($from == $v) {
          push @new_pending, $to;
          $keep = 0;
        } elsif ($to == $v) {
          push @new_pending, $from;
          $keep = 0;
        }
        $keep
      } @edges;
    }
    @pending = @new_pending;
  }
  return $eccentricity;
}

# return true if all vertices of $graph have same degree
sub edge_aref_is_regular {
  my ($edge_aref) = @_;
  my @degrees = edge_aref_degrees($edge_aref);
  ### @degrees
  foreach my $i (1 .. $#degrees) {
    if ($degrees[$i] != $degrees[0]) {
      return 0;
    }
  }
  return 1;
}

#------------------------------------------------------------------------------

sub Graph_Wiener_part_at_vertex {
  my ($graph,$vertex) = @_;
  my $total = 0;
  $graph->for_shortest_paths(sub {
                               my ($t, $u,$v, $n) = @_;
                               if ($u eq $vertex) {
                                 $total += $t->path_length($u,$v);
                               }
                             });
  return $total;
}

sub Graph_Wiener_index {
  my ($graph) = @_;
  my $total = 0;
  $graph->for_shortest_paths(sub {
                               my ($t, $u,$v, $n) = @_;
                               $total += $t->path_length($u,$v);
                             });
  return $total/2;
}

sub Graph_terminal_Wiener_index {
  my ($graph) = @_;
  my $total = 0;
  my $for = $graph->for_shortest_paths
    (sub {
       my ($t, $u,$v, $n) = @_;
       ### u: $graph->vertex_degree($u)
       ### v: $graph->vertex_degree($v)
       if ($graph->vertex_degree($u) == 1 && $graph->vertex_degree($v) == 1) {
         $total += $t->path_length($u,$v);
       }
     });
  return $total/2;
}

sub Graph_terminal_Wiener_part_at_vertex {
  my ($graph, $vertex) = @_;
  ### Graph_terminal_Wiener_part_at_vertex(): $vertex

  my $total = 0;
  my $for = $graph->for_shortest_paths
    (sub {
       my ($t, $u,$v, $n) = @_;
       # ### u: $graph->vertex_degree($u)
       # ### v: $graph->vertex_degree($v)
       ### path: "$u to $v"

       # can have $vertex not a leaf node
       if ($u eq $vertex
           && $graph->vertex_degree($v) == 1) {
         ### length: $t->path_length($u,$v)
         $total += $t->path_length($u,$v);
       }
     });
  return $total;
}

#------------------------------------------------------------------------------

# $graph is a Graph.pm.
# Return a new Graph.pm which is its line graph.
# Each vertex of the line graph is an edge of $graph and edges in the line
# graph are between those $graph edges with a vertex in common.
#
sub Graph_line_graph {
  my ($graph) = @_;
  my $line = Graph->new (undirected => $graph->is_undirected);

  $line->set_graph_attribute
    (name => join(', ',
                  ($graph->get_graph_attribute('name') // ()),
                  'line graph'));

  foreach my $from_edge ($graph->edges) {
    my $from_edge_name = join(':', @$from_edge);
    my ($from_vertex, $to_vertex) = @$from_edge;
    foreach my $to_edge ($graph->edges_at($from_vertex),
                         $graph->edges_at($to_vertex)) {
      my $to_edge_name = join(':', @$to_edge);
      if ($from_edge_name ne $to_edge_name
          && ! $line->has_edge ($from_edge_name, $to_edge_name)
          && ! $line->has_edge ($to_edge_name, $from_edge_name)) {
        $line->add_edge($from_edge_name, $to_edge_name);
      }
    }
  }
  return $line;
}

sub Graph_Easy_line_graph {
  my ($easy) = @_;

  my $line = Graph::Easy->new (undirected => $easy->is_undirected);
  foreach my $from_edge ($easy->edges) {
    my $from_name = $from_edge->name;
    foreach my $to_edge ($from_edge->from->edges,
                         $from_edge->to->edges) {
      my $to_name = $to_edge->name;
      if ($from_name ne $to_name
          && ! $line->has_edge ($from_name, $to_name)
          && ! $line->has_edge ($to_name, $from_name)) {
        $line->add_edge($from_name, $to_name);
      }
    }
  }
  return $line;
}

# Graph_Beineke_graphs() returns a list of Graph.pm graphs of Beineke G1 to G9.
use constant::defer Graph_Beineke_graphs => sub {
  require Graph::Maker::Beineke;
  map {
    Graph::Maker->new('Beineke', G=>$_, undirected=>1)
    } 1 .. 9;
};

# $graph is a Graph.pm.
# Return true if $graph is a line graph, by checking none of Beineke G1 to
# G9 are induced subgraphs.
#
sub Graph_is_line_graph_by_Beineke {
  my ($graph) = @_;
  ### Graph_is_line_graph_by_Beineke() ...
  foreach my $G (Graph_Beineke_graphs()) {
    if (Graph_is_induced_subgraph($graph, $G)) {
      ### is induced subgraph, so not line graph ...
      return 0;
    }
    ### not subgraph ...
  }
  ### final is line graph ...
  return 1;
}

#------------------------------------------------------------------------------
# Graph Doubles

# $graph is a Graph.pm.
# Return a new graph which is the bipartite double of $graph.
# The new graph is two copies of the original vertices "$v.A" and $v.B".
# An edge $u to $v in $graph becomes edges $u.A to $v.B
#                                     and  $u.B to $v.A
#
sub Graph_bipartite_double {
  my ($graph) = @_;
  my $double = $graph->new;  # same directed, countedged, etc
  foreach my $v ($graph->vertices) {
    $double->add_vertex("$v.A");
    $double->add_vertex("$v.B");
  }
  foreach my $edge ($graph->edges) {
    my ($from,$to) = @$edge;
    ### edge: "$from to $to"
    $double->add_edge("$from.A","$to.B");
    $double->add_edge("$from.B","$to.A");
  }
  return $double;
}


#------------------------------------------------------------------------------
# GraphViz2 conversions

# file:///usr/share/doc/graphviz/html/info/attrs.html

# $graph is a Graph.pm object.
# Return a GraphViz2 object.
#
sub Graph_to_GraphViz2 {
  my ($graph, %options) = @_;
  ### Graph_to_GraphViz2: %options
  require GraphViz2;
  $options{'vertex_name_type'}
    //= $graph->get_graph_attribute('vertex_name_type') // '';
  my $is_xy = ($options{'vertex_name_type'} =~ /^xy/
               || $graph->get_graph_attribute('vertex_name_type_xy'));
  my $is_xy_triangular
    = ($options{'vertex_name_type'} =~ /^xy-triangular/
       || $graph->get_graph_attribute('vertex_name_type_xy_triangular'));
  ### $is_xy

  my $name = $graph->get_graph_attribute('name');
  my $flow = ($options{'flow'} // $graph->get_graph_attribute('flow') // 'down');
  if ($flow eq 'north') { $flow = 'BT'; }
  if ($flow eq 'east')  { $flow = 'LR'; }
  my $graphviz2 = GraphViz2->new
    (global => { directed => $graph->is_directed },
     graph  => { (defined $name ? (label   => $name) : ()),
                 (defined $flow ? (rankdir => $flow) : ()),

                 # ENHANCE-ME: take this in %options somehow
                 # Scale like "3" means input coordinates are tripled, so
                 # actual drawing is 1/3 of an inch steps.
                 inputscale => 3,
               },
     node => { margin => 0,  # cf default 0.11,0.055
             },
    );

  foreach my $v ($graph->vertices) {
    my @attrs;

    if (defined (my $xy = $graph->get_vertex_attribute($v,'xy'))) {
      push @attrs, pin=>1, pos=>$xy;
    } elsif ($is_xy) {
      my ($x,$y) = split /,/, $v;
      if ($is_xy_triangular) {
        $x *= 1/2;
        $y = sprintf '%.5f', $y*sqrt(3)/2;
      }
      push @attrs, pin=>1, pos=>"$x,$y";
      ### @attrs
    } elsif (defined(my $x = $graph->get_vertex_attribute($v,'x'))
             && defined(my $y = $graph->get_vertex_attribute($v,'y'))) {
      ### pin at: "$x,$y"
      push @attrs, pin=>1, pos=>"$x,$y";
    }
    $graphviz2->add_node(name => $v,
                         margin => '0.03,0.02',  # cf default 0.11,0.055
                         height => '0.1',  # inches, minimum
                         width  => '0.1',  # inches, minimum
                         @attrs);
  }
  foreach my $edge ($graph->edges) {
    my ($from, $to) = @$edge;
    $graphviz2->add_edge(from => $from, to => $to);
  }
  return $graphviz2;
}

sub Graph_vertex_xy {
  my ($graph, $v) = @_;
  if (defined (my $xy = $graph->get_vertex_attribute($v,'xy'))) {
    return split /,/, $xy;
  }
  if ($graph->get_graph_attribute('vertex_name_type_xy_triangular')) {
    my ($x,$y) = split /,/, $v;
    return ($x*.5, $y*(sqrt(3)/2));
  }
  if ($graph->get_graph_attribute('vertex_name_type_xy')) {
    return split /,/, $v;
  }
  if (defined(my $x = $graph->get_vertex_attribute($v,'x'))
      && defined(my $y = $graph->get_vertex_attribute($v,'y'))) {
    return ($x,$y);
  }
  return ();
}
sub Graph_set_xy_points {
  my $graph = shift;
  while (@_) {
    my $v = shift;
    my $point = shift;
    ### $v
    ### $point
    $graph->set_vertex_attribute($v, x => $point->[0]);
    $graph->set_vertex_attribute($v, y => $point->[1]);
  }
}

# $graphviz2 is a GraphViz2 object.
#
sub GraphViz2_view {
  my ($graphviz2, %options) = @_;

  require File::Temp;
  my $ps = File::Temp->new (UNLINK => 0, SUFFIX => '.ps');
  my $ps_filename = $ps->filename;
  $graphviz2->run(format => 'ps',
                  output_file => $ps_filename,
                  ($options{'driver'} ? (driver => $options{'driver'}) : ()),
                  );
  postscript_view_file($ps_filename, %options);

  # $graphviz2->run(format => 'xlib',
  #                 driver => 'neato',
  #                );
}

sub parent_aref_view {
  my ($aref) = @_;
  Graph_Easy_view(parent_aref_to_Graph_Easy($aref));
}

#------------------------------------------------------------------------------

# $name is a vertex name.
# Return a form suitable for use as a PGF/Tikz node name.
# ENHANCE-ME: not quite right, would want to fixup most parens and more too.
#
sub vertex_name_to_tikz {
  my ($name) = @_;
  $name =~ s/[,:]/-/g;
  return $name;
}

# $graph is an undirected Graph.pm.
# Print some PGF/Tikz TeX nodes and edges.
# The output is a bit rough, and usually must be massaged by hand.
#
sub Graph_print_tikz {
  my ($graph) = @_;

  my $is_xy = $graph->get_graph_attribute('vertex_name_type_xy');

  my @vertices = sort $graph->vertices;
  my $flow = 'east';
  my $rows = int(sqrt(scalar(@vertices)));
  my $r = 0;
  my $c = 0;
  my %seen_vn;
  foreach my $v (@vertices) {
    my $x = ($flow eq 'west' ? -$c : $c);

    my $vn = vertex_name_to_tikz($v);
    if (exists $seen_vn{$vn}) {
      croak "Oops, duplicate tikz vertex name for \"$v\" and \"$seen_vn{$vn}\"";
    }
    $seen_vn{$vn} = $v;

    my $at = ($is_xy ? $v : "$x,$r");
    print "  \\node ($vn) at ($at) [my box] {$v};\n";
    $r++;
    if ($r >= $rows) {
      $c++;
      $r = 0;
    }
  }
  print "\n";

  my $arrow = $graph->is_directed ? "->" : "";
  foreach my $edge ($graph->unique_edges) {
    my ($from,$to) = @$edge;
    my $count = $graph->get_edge_count($from,$to);
    my $node = ($count == 1 ? ''
                : "node[pos=.5,auto=left] {$count} ");

    $from = vertex_name_to_tikz($from);
    $to   = vertex_name_to_tikz($to);
    if ($from eq $to) {
      print "  \\draw [$arrow,loop below] ($from) to $node();\n";
    } else {
      print "  \\draw [$arrow] ($from) to $node($to);\n";
    }
  }
  print "\n";
}

sub all_looks_like_consecutive_number {
  all_looks_like_number(@_) or return 0;
  my @a = sort {$a<=>$b} @_;
  foreach my $i (1 .. $#a) {
    $a[$i] == $a[$i-1] + 1 or return 0;
  }
  return 1;
}
sub all_looks_like_number {
  foreach (@_) {
    (Scalar::Util::looks_like_number($_)
     && $_ <= (1<<24))
        or return 0;
  }
  return 1;
}
sub sort_num_or_alnum {
  foreach (@_) {
    unless (Scalar::Util::looks_like_number($_)) {
      return sort @_;
    }
  }
  return sort {$a<=>$b} @_;
}

sub Graph_print_dreadnaut {
  my ($graph) = @_;
  print Graph_dreadnaut_str($graph);
}
sub Graph_dreadnaut_str {
  my ($graph, %options) = @_;
  my @vertices = $graph->vertices;
  my $base;
  if (@vertices && all_looks_like_number(@vertices)) {
    ### numeric vertices ...
    @vertices = sort {$a<=>$b} @vertices;
    $base = $vertices[0];
  } else {
    ### non-numeric vertices, sort ...
    @vertices = sort @vertices;
    $base = $options{'base'} || 0;
  }
  my %vertex_to_n;
  @vertex_to_n{@vertices} = $base .. $base+$#vertices;  # hash slice
  ### %vertex_to_n

  my $str = '';
  $str .= ($graph->is_directed ? 'd' : '-d')
    . ' n='.scalar(@vertices)
    . " \$=$base g";
  my $comma = '';
  my $prev_i = 0;
  my @edges = sort {$vertex_to_n{$a->[0]} <=> $vertex_to_n{$b->[0]}
                      || $vertex_to_n{$a->[1]} <=> $vertex_to_n{$b->[1]}}
    $graph->edges;
  ### num edges: scalar(@edges)

  my $prev_from = $base;
  my $join = '';
  foreach my $edge (@edges) {
    ### $edge
    $str .= $comma;
    my $from = $vertex_to_n{$edge->[0]};
    my $to   = $vertex_to_n{$edge->[1]};
    ### indices: "$from to $to"
    if ($from != $prev_from) {
      $str .= ($from == $prev_from + 1 ? ';'
               : "$join$from:");
      $join = '';
      $prev_from = $from;
    }
    $str .= "$join$to";
    $join = ' ';
  }
  ### $str
  return $str . ".";
}

sub Graph_run_dreadnaut {
  my ($graph, %options) = @_;
  require IPC::Run;
  my $str = Graph_dreadnaut_str($graph,%options) . " a x\n";
  if ($options{'verbose'}) {
    print $str;
  }
  if (! IPC::Run::run(['dreadnaut'], '<',\$str)) {
    die "dreadnaut: $!";
  }
}


#------------------------------------------------------------------------------

# $graph is an undirected Graph.pm.
# Return the clique number of $graph.
# The clique number is the number of vertices in the maximum clique
# (complete graph) contained in $graph.
# Currently this is a brute force search, so quite slow and suitable only for
# small number of vertices.
#
sub Graph_clique_number {
  my ($graph) = @_;

  my @vertices = sort $graph->vertices;
  my @clique = (-1);
  my $maximum_clique_size = 0;
  my $pos = 0;
 OUTER: for (;;) {
    ### at: join(',',@clique[0..$pos])
    if (++$clique[$pos] > $#vertices) {
      # backtrack
      if (--$pos < 0) {
        last;
      }
      next;
    }
    my $v = $vertices[$clique[$pos]];
    foreach my $i (0 .. $pos-1) {
      if (! $graph->has_edge($v, $vertices[$clique[$i]])) {
        next OUTER;
      }
    }
    $pos++;
    if ($pos > $maximum_clique_size) {
      # print "  new high $maximum_clique_size\n";
      $maximum_clique_size = $pos;
    }
    if ($pos > $#vertices) {
      # $graph is a complete-N
      last;
    }
    $clique[$pos] = $clique[$pos-1];
  }
  return $maximum_clique_size;
}

# $graph is a Graph.pm and @vertices are vertex names in it.
# Return true if those vertices are a clique, meaning edge between all pairs.
sub Graph_is_clique {
  my ($graph, @vertices) = @_;
  foreach my $i (0 .. $#vertices) {
    $graph->has_vertex($vertices[$i]) or die;
    foreach my $j (0 .. $#vertices) {
      next if $i == $j;
      ### has: "$vertices[$i] $vertices[$j] is ".($graph->has_edge($vertices[$i], $vertices[$j])||0)
      $graph->has_edge($vertices[$i], $vertices[$j]) or return 0;
    }
  }
  return 1;
}

#------------------------------------------------------------------------------

# $graph is a tree
# $v is a child node of $parent
# Return the depth of the subtree $v and deeper underneath $parent.
# If $v is a leaf then it is the entire subtree and the return is depth 1.
#
sub Graph_subtree_depth {
  my ($graph, $parent, $v) = @_;
  ### $parent
  ### $v
  $graph->has_edge($parent,$v) or die "oops, $parent and $v not adjacent";
  my $depth = 0;
  my %seen = ($parent => 1, $v => 1);
  my @pending = ($v);
  do {
    @pending = map {$graph->neighbours($_)} @pending;
    @pending = grep {! $seen{$_}++} @pending;
    $depth++;
  } while (@pending);
  return $depth;
}

# $graph is a tree
# $v is a child node of $parent
# return the children of $v, being all neighbours except $parent
sub Graph_subtree_children {
  my ($graph, $parent, $v) = @_;
  return grep {$_ ne $parent} $graph->neighbours($v);
}


#------------------------------------------------------------------------------

# $edge_aref is an arrayref [ [from,to], [from,to], ... ]
# where each vertex is integer 0 upwards
# Return the number of vertices, which means the maximum + 1 of the vertex
# numbers in the elements.
#
sub edge_aref_num_vertices {
  my ($edge_aref) = @_;
  if (! @$edge_aref) { return 0; }
  return max(map {@$_} @$edge_aref) + 1;
}

# $edge_aref is an arrayref [ [from,to], [from,to], ... ]
# where each vertex is integer 0 upwards forming a tree with root 0
# Return an arrayref of the parent of each vertex, so $a->[i] = parent of i
#
sub edge_aref_to_parent_aref {
  my ($edge_aref) = @_;
  ### edge_aref_to_parent_aref() ...

  my @neighbours;
  foreach my $edge (@$edge_aref) {
    my ($from, $to) = @$edge;
    push @{$neighbours[$from]}, $to;
    push @{$neighbours[$to]}, $from;
  }

  my @parent;
  my @n_to_v = (0);
  my @v_to_n = (0);
  my $upto_v = 1;
  for (my $v = 0; $v < $upto_v; $v++) {
    ### neighbours: "$v=n$v_to_n[$v] to n=".join(',',@{$neighbours[$v_to_n[$v]]})
    foreach my $n (@{$neighbours[$v_to_n[$v]]}) {
      if (! defined $n_to_v[$n]) {
        $n_to_v[$n] = $upto_v;
        $v_to_n[$upto_v] = $n;
        $parent[$upto_v] = $v;
        $upto_v++;
      }
    }
  }
  foreach my $edge (@$edge_aref) {
    foreach my $n (@$edge) {
      $n = $n_to_v[$n]; # mutate array
    }
  }

  ### @parent
  ### num_vertices: scalar(@parent)
  return \@parent;
}

# $parent_aref is an arrayref where $a->[i] = parent of i
# vertices are integers 0 upwards
# Return an edge aref [ [from,to], [from,to], ... ]
#
sub parent_aref_to_edge_aref {
  my ($parent_aref) = @_;
  return [ map {[$parent_aref->[$_] => $_]} 1 .. $#$parent_aref ];
}

# $parent_aref is an arrayref where $a->[i] = parent of i
# vertices are integers 0 upwards
# Return a Graph::Easy
#
sub parent_aref_to_Graph_Easy {
  my ($parent_aref) = @_;
  require Graph::Easy;
  my $graph = Graph::Easy->new(undirected => 1);
  if (@$parent_aref) {
    $graph->add_vertex(0);
    foreach my $v (1 .. $#$parent_aref) {
      $graph->add_edge($v,$parent_aref->[$v]);
    }
  }
  return $graph;
}

#------------------------------------------------------------------------------

# $graph is a Graph.pm.
# Modify $graph by changing the name of vertex $old_name to $new_name.
# If $old_name and $new_name are the same then do nothing.
# Otherwise $new_name should not exist already.
#
sub Graph_rename_vertex {
  my ($graph, $old_name, $new_name) = @_;
  ### $old_name
  ### $new_name

  return if $old_name eq $new_name;
  if ($graph->has_vertex($new_name)) {
    croak "Graph vertex \"$new_name\" exists already";
  }

  $graph->add_vertex($new_name);
  foreach my $edge ($graph->edges_at($old_name)) {
    my ($from,$to) = @$edge;
    if ($from eq $old_name) { $from = $new_name; }
    if ($to   eq $old_name) { $to   = $new_name; }
    ### $from
    ### $to
    $graph->add_edge($from,$to);
  }
  $graph->delete_vertex($old_name);
}

# $graph is a Graph.pm.
# Return a new vertex name for $graph, one which does not otherwise occur in
# $graph.
#
sub Graph_new_vertex_name {
  my ($graph, $prefix) = @_;
  if (! defined $prefix) { $prefix = ''; }
  my $upto = $graph->get_graph_attribute('Graph_new_vertex_name_upto') // 0;
  $upto++;
  $graph->set_graph_attribute('Graph_new_vertex_name_upto',$upto);
  return "$prefix$upto";
}

# $graph is a Graph.pm.
# Add vertices to pad out existing vertices to all degree $N.
sub Graph_pad_degree {
  my ($graph, $N) = @_;
  my $upto = 1;
  my @original_vertices = $graph->vertices;
  foreach my $v (@original_vertices) {
    while ($graph->vertex_degree($v) < $N) {
      $graph->add_edge($v, Graph_new_vertex_name($graph));
      $graph->set_graph_attribute('vertex_name_type',undef);
    }
  }
  return $graph;
}

# $graph is a Graph.pm.
sub Graph_degree_sequence {
  my ($graph) = @_;
  return sort {$a<=>$b} map {$graph->vertex_degree($_)} $graph->vertices;
}

#------------------------------------------------------------------------------

# $graph is a Graph.pm.
# Replace each vertex by a star of N vertices.
# Existing edges become edges between an arm of the new stars.
# All vertices must be degree <= N-1 (the arms of the stars)
#
# Key/value options are
#
#     edges_between => $integer, default 1
#       Number of edges in connections between new stars.
#       Default 1 is replacing each edge by an edge between the stars.
#       > 1 means extra vertices for those connections.
#       0 means the stars have a vertex in common for existing edges.
#
sub Graph_star_replacement {
  my ($graph, $N, %options) = @_;
  my $new_graph = $graph->new (undirected => $graph->is_undirected);
  my $edges_between = $options{'edges_between'} // 1;
  ### $edges_between

  my $upto = 1;
  my %v_to_arms;
  foreach my $v ($graph->vertices) {
    my $centre = $upto++;
    foreach my $i (2 .. $N) {
      my $arm = $upto++;
      $new_graph->add_edge($centre,$arm);
      push @{$v_to_arms{$v}}, $arm;
    }
  }

  foreach my $edge ($graph->edges) {
    my ($u,$v) = @$edge;
    $u = (pop @{$v_to_arms{$u}}) // croak "oops, degree > $N";
    $v = (pop @{$v_to_arms{$v}}) // croak "oops, degree > $N";

    if ($edges_between == 0) {
      Graph_merge_vertices($new_graph, $u, $v);
    } else {
      my @between = map {my $b = $upto++; $b} 2 .. $edges_between;
      $new_graph->add_path($u, @between, $v);
    }
  }

  if (defined (my $name = $graph->get_graph_attribute('name'))) {
    my $append = ", $N-star rep";
    if ($name =~ /\Q$append\E$/) { $name .= ' 2'; }
    elsif ($name =~ s{(\Q$append\E )(\d+)$}{$1.($2+1)}e) { }
    else { $name .= $append; }
    $graph->set_graph_attribute (name => $name);
    ### $name
  }
  return $new_graph;
}

sub _closest_xy_pair {
  my ($aref, $bref) = @_;
  if (@$aref == 0 || @$bref == 0) { return; }
  my $min_a = 0;
  my $min_b = 0;
  my $min_norm;
  foreach my $a (0 .. $#$aref) {
    my ($ax,$ay) = split /,/, $aref->[$a];
    foreach my $b (0 .. $#$bref) {
      my ($bx,$by) = split /,/, $bref->[$b];
      my $norm = ($ax-$bx)**2 + ($ay-$by)**2;
      if (! defined $min_norm || $norm < $min_norm) {
        $min_a = $a;
        $min_b = $b;
        $min_norm = $norm;
      }
    }
  }
  return (splice(@$aref, $min_a, 1),
          splice(@$bref, $min_b, 1));
}

# Graph_merge_vertices($graph, $v, $v2, $v3, ...)
# $graph is a Graph.pm
# Modify $graph to merge all the given vertices into one.
# Edges going to any of them are moved to go to $v, and the rest deleted.
# Only for undirected graphs currently.
#
sub Graph_merge_vertices {
  my $graph = shift;
  $graph->expect_undirected;
  my $v = shift;
  foreach my $other (@_) {
    ### Graph_merge_vertices(): "$v, $other"
    foreach my $neighbour ($graph->neighbours($other)) {
      ### $neighbour
      unless ($neighbour eq $v) {
        $graph->add_edge ($v, $neighbour);
      }
    }
    $graph->delete_vertex($other);
  }
}

# $graph is a Graph.pm.
# Replace each vertex by an N-cycle.
# Existing edges become edges between vertices of the cycles, consecutively
# around the cycle.
#
sub Graph_cycle_replacement {
  my ($graph, $N, %options) = @_;
  my $edges_between = $options{'edges_between'} // 1;
  my $vertex_name_type = $graph->get_graph_attribute('vertex_name_type') // '';
  my $xy = ($vertex_name_type =~ /^xy/) && $N==4;
  ### $vertex_name_type
  ### $xy

  my $new_graph = $graph->new (undirected => $graph->is_undirected);
  my $upto = 1;
  my %v_to_arms;
  foreach my $v ($graph->vertices) {
    my @c;
    if ($xy) {
      my ($x,$y) = split /,/,$v;
      $x *= $edges_between+4;
      $y *= $edges_between+4;
      @c = ( ($x+1).','.($y+1),
             ($x-1).','.($y+1),
             ($x-1).','.($y-1),
             ($x+1).','.($y-1) );
    } else {
      @c = map {my $c = $upto++; $c} 1 .. $N;
    }
    foreach my $c (@c) { die if $new_graph->has_vertex($c); }
    $new_graph->add_cycle(@c);
    $v_to_arms{$v} = \@c;
  }

  foreach my $edge ($graph->edges) {
    my ($u,$v) = @$edge;
    my @between;
    if ($xy) {
      ($u,$v) = _closest_xy_pair($v_to_arms{$u},
                                 $v_to_arms{$v})
        or croak "oops, degree > $N";
      # $u = (pop @{$v_to_arms{$u}}) // croak "oops, degree > $N";
      # $v = (pop @{$v_to_arms{$v}}) // croak "oops, degree > $N";
      my ($ux,$uy) = split /,/,$u;
      my ($vx,$vy) = split /,/,$v;
      @between = map { my $x = $ux + ($vx-$ux)/($edges_between+2);
                       my $y = $uy + ($vy-$uy)/($edges_between+2);
                       my $b = "$x,$y";
                       die if $new_graph->has_vertex($b);
                       $b;
                     } 1 .. $edges_between;
    } else {
      $u = (shift @{$v_to_arms{$u}}) // croak "oops, degree > $N";
      $v = (shift @{$v_to_arms{$v}}) // croak "oops, degree > $N";
      @between = map {my $b = $upto++; $b} 1 .. $edges_between;
    }
    if ($edges_between == 0) {
      Graph_merge_vertices($new_graph, $u, $v);
    } else {
      $new_graph->add_path($u, @between, $v);
    }
  }

  if (defined (my $name = $graph->get_graph_attribute('name'))) {
    my $append = ", $N-star rep";
    if ($name =~ /\Q$append\E$/) {
      $name .= ' 2';
    } elsif ($name =~ s{(\Q$append\E )(\d+)$}{$1.($2+1)}e) {
    } else {
      $name .= $append;
    }
    $new_graph->set_graph_attribute (name => $name);
  }
  $new_graph->set_graph_attribute('vertex_name_type', $vertex_name_type);

  return $new_graph;
}

#------------------------------------------------------------------------------

# $graph is a Graph.pm.
# Return a list of vertices which are a path achieving the eccentricity of $u.
#
# FIXME: is $graph->longest_path args ($u,$v) a documented feature?
sub Graph_eccentricity_path {
  my ($graph, $u) = @_;
  $graph->expect_undirected;
  my $max = 0;
  my $max_v;
  for my $v ($graph->vertices) {
    next if $u eq $v;
    my $len = $graph->path_length($u, $v);
    if (defined $len && (! defined $max || $len > $max)) {
      $max = $len;
      $max_v = $v;
    }
  }
  return $graph->longest_path($u,$max_v);
}


#------------------------------------------------------------------------------

# $graph is a Graph.pm undirected tree.
# Return ($eccentricity, $vertex,$vertex) which is the centre 1 or 2 vertex
# names and their eccentricity.
# Only tested on bicentral trees.
# FIXME: the return is not eccentricity but num vertices to reach maximum?
sub Graph_tree_centre_vertices {
  my ($graph) = @_;

  {
    my $eccentricity = 0;
    my %seen;
    my %unseen = map {$_=>1} $graph->vertices;
    my @prev_unseen;
    for (;;) {
      ### seen: join(' ',keys %seen)
      ### unseen: join(' ',keys %unseen)
      ### $eccentricity
      %unseen or last;
      $eccentricity++;
      @prev_unseen = keys %unseen;
      my @leaves;
      foreach my $v (@prev_unseen) {
        my @neighbours = grep {! exists $seen{$_}} $graph->neighbours($v);
        if (@neighbours <= 1) {
          push @leaves, $v;
        }
      }
      ### @leaves
      delete @unseen{@leaves};  # leaf nodes go from unseen to seen
      @seen{@leaves} = ();
    }
    return ($eccentricity, @prev_unseen);
  }
  {
    $graph = $graph->copy;
    my @prev_vertices;
    for (;;) {
      my @vertices = $graph->vertices
        or last;
      @prev_vertices = @vertices;
      my @leaves = grep {$graph->degree($_) <= 1} @vertices;
      $graph->delete_vertices(@leaves);
    }
    return @prev_vertices;
  }
}

# $graph is an undirected connected Graph.pm.
# Return a list of its leaf vertices.
#
sub Graph_leaf_vertices {
  my ($graph) = @_;
  return grep {$graph->vertex_degree($_)<=1} $graph->vertices;
}

# $graph is a Graph.pm undirected tree.
# Return a list of vertices which attain the diameter of tree $graph.
#
sub Graph_tree_diameter_path {
  my ($graph) = @_;
  if ($graph->vertices == 0) { return; }
  my ($eccentricity, @centres) = Graph_tree_centre_vertices($graph);
  ### @centres
  my @paths = ([ $centres[0] ]);
  my @prev_paths = @paths;
  for (;;) {
    ### paths: map {join(',',@$_)} @paths
    my @new_paths;
    foreach my $path (@paths) {
      my $v = $path->[-1];
      foreach my $neighbour ($graph->neighbours($v)) {
        next if @$path>=2 && $neighbour eq $path->[-2];
        push @new_paths, [@$path,$neighbour];
      }
    }
    if (@new_paths) {
      @prev_paths = @paths;
      @paths = @new_paths;
    } else {
      last;
    }
  }
  my $path = shift @paths;
  ### final path: join(',',@$path)
  push @paths, @prev_paths;
  if (@paths) {
    foreach my $other_path (@paths) {
      ### final path: join(',',@$path)
      ### consider other: join(',',@$other_path)
      if (@$other_path < 2 || $other_path->[1] ne $path->[1]) {
        my @join = reverse @$path;
        pop @join;
        push @join, @$other_path;
        ### join to: join(',',@join)
        $path = \@join;
        last;
      }
    }
  }
  ### $eccentricity
  ### path length: scalar(@$path)
  scalar(@$path) == 2*$eccentricity - (@centres==1)
    or die "oops";
  return @$path;
}

# $graph is an undirected connected Graph.pm.
# Return the number of paths attaining the diameter of $graph.
# A path u--v is counted just once, not also v--u.
#
sub Graph_diameter_count {
  my ($graph) = @_;
  if ($graph->vertices <= 1) {
    return 1;
  }
  my $diameter = 0;
  my $count = 0;
  $graph->for_shortest_paths(sub {
                               my ($t, $u,$v, $n) = @_;
                               my $len = $t->path_length($u,$v);
                               if ($len > $diameter) {
                                 ### new high path length: $len
                                 $count = 0;
                                 $diameter = $len;
                               }
                               if ($len == $diameter) {
                                 $count++;
                                 ### equal high path length to count: $count
                               }
                             });
  ### $diameter
  return ($graph->is_undirected ? $count/2 : $count);
}

# $graph is a Graph.pm.
# Insert $n new vertices into each of its edges.
# If $n omitted or undef then default 1 vertex in each edge.
sub Graph_subdivide {
  my ($graph, $n) = @_;
  if (! defined $n) { $n = 1; }
  foreach my $edge ($graph->edges) {
    $graph->delete_edge (@$edge);
    my $prefix = "$edge->[0]-$edge->[1]-";
    $graph->add_path ($edge->[0],
                      (map {Graph_new_vertex_name($graph,$prefix)} 1 .. $n),
                      $edge->[1]);
  }
  if ($n && $graph->edges
      && defined (my $name = $graph->get_graph_attribute('name'))) {
    $graph->set_graph_attribute (name =>
                                 "$name subdivision".($n > 1 ? " $n" : ""));
  }
  return $graph;
}

#------------------------------------------------------------------------------
# Independence Number

# $graph is a Graph.pm undirected tree or forest.
# Return its independence number.
#
sub Graph_tree_indnum {
  my ($graph) = @_;
  ### Graph_tree_indnum: "num_vertices ".scalar($graph->vertices)
  $graph->expect_acyclic;

  $graph = $graph->copy;
  my $indnum = 0;
  my %exclude;
 OUTER: while ($graph->vertices) {
    foreach my $v ($graph->vertices) {
      my $degree = $graph->vertex_degree($v);
      next unless $degree <= 1;
      my ($u) = $graph->neighbours($v);
      ### consider: "$v degree $degree neighbours ".($u//'undef')

      if (delete $exclude{$v}) {
        ### exclude ...
      } else {
        ### leaf include ...
        $indnum++;
        if (defined $u) { $exclude{$u} = 1; }
      }
      $graph->delete_vertex($v);
      next OUTER;
    }
    die "oops, not a tree";
  }
  return $indnum;
}

sub Graph_make_most_indomsets {
  my ($n) = @_;
  my $graph = Graph->new (undirected=>1);
  my $v = 0;
  while ($n > 0) {
    if ($v) { $graph->add_edge(0,$v) }  # to x
    my $u = $v;
    my $size = 3 + (($n%3)!=0);
    foreach my $i (0 .. $size-1) { # triangle or complete-4
      foreach my $j (0 .. $i-1) {
        $graph->add_edge($u+$i, $u+$j);
      }
    }
    $n -= $size;
    $v += $size;
  }
  return $graph;
}

sub Graph_is_indset {
  my ($graph,$aref) = @_;
  foreach my $from (@$aref) {
    foreach my $to (@$aref) {
      if ($graph->has_edge($from,$to)) {
        return 0;
      }
    }
  }
  return 1;
}

sub Graph_indnum_and_count {
  my ($graph) = @_;
  require Algorithm::ChooseSubsets;
  my @vertices = sort $graph->vertices;
  my $it = Algorithm::ChooseSubsets->new(\@vertices);
  my $indnum = 0;
  my $count = 0;
  while (my $aref = $it->next) {
    if (Graph_is_indset($graph,$aref)) {
      if (@$aref == $indnum) {
        $count++;
      } elsif (@$aref > $indnum) {
        $indnum = @$aref;
        $count = 1;
      }
    }
  }
  return ($indnum, $count);
}


#------------------------------------------------------------------------------
# Dominating Sets Count

# with(n)   = prod(child any)     # sets including parent
# undom(n)  = prod(child dom)     # sets without parent and parent undominated
# dom(n)    = prod(child with + dom) - prod(child dom)
#                                 # sets without parent and parent dominated
# T(n)      = with(n) + dom(n);
#
# with + dom = any - undom
#
#                *
#           /    |     \
#       *        *        *
#      /|\      /|\      /|\
#     * * *    * * *    * * *
#
# path  1--2      2 with + 1 without = 3 any     0 without undom
# path  1--2--3   3 with + 2 without = 5 any     1 without undom
#                                                2 without dom
#   cannot e,1,3

# $graph is a Graph.pm tree.
# Return the number of dominating sets in $graph.
#
sub Graph_tree_domsets_count {
  my ($graph) = @_;
  require Math::BigInt;
  $graph = $graph->copy;
  $graph->vertices || return 1;  # empty graph
  my %data;

  my $one = Math::BigInt->new(1);

 OUTER: for (;;) {
    foreach my $v (sort $graph->vertices) {
      my $degree = $graph->vertex_degree($v);
      next unless $degree <= 1;

      # with(n)          = prod(c any)
      # without(n)       = prod(c with + dom = domsets)
      # without_undom(n) = prod(c dom);
      #
      my $c_with          = $data{$v}->{'with'} // $one;
      my $c_without_undom = $data{$v}->{'without_undom'} // $one;
      my $c_without       = $data{$v}->{'without'} // $one;
      my $c_without_dom   = $c_without - $c_without_undom;
      my $c_domsets       = $c_with + $c_without_dom;
      my $c_any           = $c_with + $c_without;

      ### consider: "$v deg=$degree  with $c_with, without $c_without, without_undom $c_without_undom"
      ### consider: "   so without_dom=$c_without_dom domsets=$c_domsets any=$c_any"

      if ($degree == 0) {
        return $c_domsets;
      }

      my ($u) = $graph->neighbours($v);
      $data{$u}->{'with'}          //= $one;
      $data{$u}->{'without'}       //= $one;
      $data{$u}->{'without_undom'} //= $one;
      $data{$u}->{'with'}          *= $c_any;
      $data{$u}->{'without'}       *= $c_domsets;
      $data{$u}->{'without_undom'} *= $c_without_dom;

      delete $data{$v};
      $graph->delete_vertex($v);
      next OUTER;
    }
    die "oops, not a tree  $graph";
  }

  # OUTER: for (;;) {
  #    foreach my $v (sort $graph->vertices) {
  #      my $degree = $graph->vertex_degree($v);
  #      next unless $degree <= 1;
  #
  #      $data{$v}->{'prod_c_any'}         //= $one;
  #      $data{$v}->{'prod_c_dom'}         //= $one;
  #      $data{$v}->{'prod_c_with_or_dom'} //= $one;
  #
  #      # with(n)   = prod(c any)
  #      # undom(n)  = prod(c dom);
  #      # dom(n)    = prod(c with + dom) - prod(c dom)
  #      #
  #      my $with  = $data{$v}->{'prod_c_any'};
  #      my $undom = $data{$v}->{'prod_c_dom'};
  #      my $dom   = $data{$v}->{'prod_c_with_or_dom'} - $undom;
  #      my $ret = $with + $dom;
  #      my $any = $ret + $undom;
  #
  #      ### consider: "$v deg=$degree  prods $data{$v}->{'prod_c_any'}, $data{$v}->{'prod_c_dom'}, $data{$v}->{'prod_c_with_or_dom'}"
  #      ### consider: "   with $with dom $dom undom=$undom, ret $ret any $any"
  #
  #      if ($degree == 0) {
  #        return $ret;
  #      }
  #
  #      my ($u) = $graph->neighbours($v);
  #      $data{$u}->{'prod_c_any'}         //= $one;
  #      $data{$u}->{'prod_c_dom'}         //= $one;
  #      $data{$u}->{'prod_c_with_or_dom'} //= $one;
  #      $data{$u}->{'prod_c_any'}         *= $any;
  #      $data{$u}->{'prod_c_dom'}         *= $dom;
  #      $data{$u}->{'prod_c_with_or_dom'} *= $ret;
  #
  #      delete $data{$v};
  #      $graph->delete_vertex($v);
  #      next OUTER;
  #    }
  #    die "oops, not a tree  $graph";
  #  }
}

#        1 2 3 4 5
# path 1,1,2,2,4,4,7,9,13,18,25,36,49
#   1   with=1=1+0  without=0=0+1  domsets=1+0 = 1
#   2   with=1=1+0  without=1=1+0  domsets=1+1 = 2
#   3   with=2=1+1  without=2=1+1  domsets=1+1 = 2
#   4   with=2=1+1  without=3=2+1  domsets=2+2 = 4
#   5   with=4=1+3  without=4=2+2  domsets=4+2 = 6
#
#  1,3,4  without_dom
#   2,4   without_dom
#  1,3,5  with_unreq
#   2,5   with_req
#  1,3,4,5  not minimal
#   2,4,5   with_unreq but itself not minimal
#

# $graph is a Graph.pm tree.
# Return the number of minimal dominating sets in $graph.
#
sub Graph_tree_minimal_domsets_count {
  my ($graph) = @_;
  return tree_minimal_domsets_count_data_ret
    (Graph_tree_minimal_domsets_count_data($graph));
}

# $graph is a Graph.pm tree.
# Return a hashref of data counting minimal dominating sets in $graph.
#
sub Graph_tree_minimal_domsets_count_data {
  my ($graph) = @_;
  require Math::BigInt;
  $graph->vertices
    || return tree_minimal_domsets_count_data_initial();  # empty graph
  $graph = $graph->copy;
  my %data;
  foreach my $v ($graph->vertices) {
    $data{$v} = tree_minimal_domsets_count_data_initial();
  }
 OUTER: for (;;) {
    foreach my $c (sort {$a cmp $b} $graph->vertices) {
      my $degree = $graph->vertex_degree($c);
      next unless $degree <= 1;

      my ($v) = $graph->neighbours($c)
        or return $data{$c};  # root

      $data{$v} //= tree_minimal_domsets_count_data_initial();
      tree_minimal_domsets_count_data_product_into
        ($data{$v},
         delete($data{$c}) // tree_minimal_domsets_count_data_initial());
      $graph->delete_vertex($c);
      next OUTER;
    }
    die "oops, not a tree  $graph";
  }
}
sub tree_minimal_domsets_count_data_initial {
  my $zero = Math::BigInt->new(0);
  my $one  = Math::BigInt->new(1);
  $zero = 0;
  $one  = 1;
  return { with              => $one,
           with_notreq       => $one,
           with_min_notreq   => $one,
           without_dom_sole  => $zero,
           without_notsole   => $one,
           without_undom     => $one,
         };
}
sub tree_minimal_domsets_count_data_ret {
  my ($data) = @_;
  return ($data  ->{'with'}
          - $data->{'with_notreq'}
          + $data->{'with_min_notreq'}
          + $data->{'without_dom_sole'}
          + $data->{'without_notsole'}
          - $data->{'without_undom'});
}

# The args are 0 or more tree_minimal_domsets hashrefs.
# Return their product.  This is a tree_minimal_domsets hashref for a
# vertex which has the given args as child vertices.
#
sub tree_minimal_domsets_count_data_product {
  return tree_minimal_domsets_count_data_product_into
    (tree_minimal_domsets_count_data_initial(), @_);
}

# $p is a tree_minimal_domsets hashref and zero or more further args likewise
# which are children of $p.
# Return their product for $p with those children.
#
sub tree_minimal_domsets_count_data_product_into {
  ### tree_minimal_domsets_count_data_product_into() ...
  my $p = shift;
  ### $p
  foreach my $v (@_) {
    # ### $v
    my $v_with_notmin_notreq  = $v->{'with_notreq'} - $v->{'with_min_notreq'};
    my $v_without_dom_notsole = $v->{'without_notsole'} - $v->{'without_undom'};
    my $v_without_dom         = $v->{'without_dom_sole'} + $v_without_dom_notsole;
    my $v_mindom              = ($v->{'with'} - $v_with_notmin_notreq   # with_min
                                 + $v_without_dom);

    my $v_with_req = $v->{'with'} - $v->{'with_notreq'};
    $p->{'with'}            *= $v_with_req + $v->{'without_notsole'};
    $p->{'with_notreq'}     *= $v_with_req + $v_without_dom_notsole;
    $p->{'with_min_notreq'} *=               $v_without_dom_notsole;

    $p->{'without_dom_sole'} = ($p->{'without_dom_sole'} * $v_without_dom
                                + $p->{'without_undom'} * $v_with_notmin_notreq);
    $p->{'without_notsole'} *= $v_mindom;
    $p->{'without_undom'}   *= $v_without_dom;
  }
  return $p;
}

# $graph is a Graph.pm.
# $aref is an arrayref of vertex names.
# Return true if these vertices are a dominating set in $graph.
#
sub Graph_is_domset {
  my ($graph, $aref) = @_;
  my %vertices = map {$_=>1} $graph->vertices;
  delete @vertices{@$aref,
                     map {$graph->neighbours($_)} @$aref};
  return keys(%vertices) == 0;
}

# $graph is a Graph.pm.
# $aref is an arrayref of vertex names.
# Return true if these vertices are minimal for the amount of $graph they
# dominate, meaning any vertex removed would reduce the amount of $graph
# dominated.
#
sub Graph_domset_is_minimal {
  my ($graph, $aref) = @_;
  my %count;
  foreach my $v (@$aref) {
    foreach my $d ($v, $graph->neighbours($v)) {
      $count{$d}++;
    }
  }
 V: foreach my $v (@$aref) {
    foreach my $d ($v, $graph->neighbours($v)) {
      if ($count{$d} < 2) { next V; }
    }
    return 0;  # $v and neighbours all count >=2
  }
  return 1;
}

# $graph is a Graph.pm.
# $aref is an arrayref of vertex names.
# Return true if these vertices are a minimal dominating set in $graph.
#
sub Graph_is_minimal_domset {
  my ($graph, $aref) = @_;
  return Graph_is_domset($graph,$aref) && Graph_domset_is_minimal($graph,$aref);
}

# Return the number of minimal dominating sets in $graph by iterating
# through all vertex sets and testing by the Graph_is_minimal_domset()
# predicate.  This is quite slow so suitable only for small number of
# vertices.
#
sub Graph_minimal_domsets_count_by_pred {
  my ($graph) = @_;
  require Algorithm::ChooseSubsets;
  my $count = 0;
  my @vertices = sort $graph->vertices;
  my $it = Algorithm::ChooseSubsets->new(\@vertices);
  while (my $aref = $it->next) {
    if (Graph_is_minimal_domset($graph,$aref)) {
      $count++;
    }
  }
  return $count;
}

# $graph is a Graph.pm.
# $aref is an arrayref of vertex names.
# Return true if these vertices are a total dominating set in $graph.
# Every vertex must have one of $aref as a neighbour.
# Unlike a plain dominating set, $aref vertices to not dominate themselves,
# they must have a neighbour in the set.
#
sub Graph_is_total_domset {
  my ($graph, $aref) = @_;
  my %vertices = map {$_=>1} $graph->vertices;
  delete @vertices{map {$graph->neighbours($_)} @$aref};
  return keys(%vertices) == 0;
}


#------------------------------------------------------------------------------
# Domination Number

# Cockayne, Goodman, Hedetniemi, "A Linear Algorithm for the Domination
# Number of a Tree", Information Processing Letters, volume 4, number 2,
# November 1975, pages 41-44.

# $graph is a Graph.pm undirected tree or forest.
# Return its domination number.
#
sub Graph_tree_domnum {
  my ($graph) = @_;
  ### Graph_tree_domnum: "num_vertices ".scalar($graph->vertices)
  $graph->expect_acyclic;

  $graph = $graph->copy;
  my $domnum = 0;
  my %mtype = map {$_=>'bound'} $graph->vertices;
 OUTER: while ($graph->vertices) {
    foreach my $v ($graph->vertices) {
      my $degree = $graph->vertex_degree($v);
      next unless $degree <= 1;
      ### consider: $v
      ### $degree

      my ($u) = $graph->neighbours($v);
      if ($mtype{$v} eq 'free') {
        ### free, delete ...

      } elsif ($mtype{$v} eq 'bound') {
        ### bound ...
        if (defined $u) {
          ### set neighbour $u required ...
          $mtype{$u} = 'required';
        } else {
          ### no neighbour, domnum++ ...
          $domnum++;
        }

      } elsif ($mtype{$v} eq 'required') {
        ### required, domnum++ ...
        $domnum++;
        if (defined $u && $mtype{$u} eq 'bound') {
          ### set neighbour $u free ...
          $mtype{$u} = 'free';
        }
      } else {
        die;
      }
      delete $mtype{$v};
      $graph->delete_vertex($v);
      next OUTER;
    }
    die "oops, not a tree";
  }
  return $domnum;
}



#------------------------------------------------------------------------------

# $graph is a Graph.pm and $sptg is its $graph->SPT_Dijkstra() tree.
# Set $sptg vertex attribute "count" on each vertex $v which gives the count
# of number of paths from SPT_Dijkstra_root to that $v.
#
sub Graph_SPT_counts {
  my ($graph,$sptg, %options) = @_;
  my $start = $sptg->get_graph_attribute('SPT_Dijkstra_root');
  my $one = $options{'one'} || 1;
  $sptg ->set_vertex_attribute ($start,'count',$one);
  foreach my $from (sort {($sptg->get_vertex_attribute($a,'weight') || 0)
                            <=>
                            ($sptg->get_vertex_attribute($b,'weight') || 0)}
                    $sptg->vertices) {
    my $target_distance
      = ($sptg->get_vertex_attribute($from,'weight') || 0) + 1;
    my $from_count = $sptg ->get_vertex_attribute($from,'count');
    ### from: $from . ' weight ' .($sptg->get_vertex_attribute($from,'weight') || 0)
    ### $from_count
    ### $target_distance
    foreach my $to ($graph->neighbours($from)) {
      if (($sptg->get_vertex_attribute($to,'weight') || 0)
          == $target_distance) {
        ### to: $to . ' weight ' .($sptg->get_vertex_attribute($to,'weight') || 0)
        $sptg ->set_vertex_attribute
          ($to,'count',
           $from_count + ($sptg ->get_vertex_attribute($to,'count') || 0));
      } else {
        ### skip: $to . ' weight ' .($sptg->get_vertex_attribute($to,'weight') || 0)
      }
    }
  }
}


#------------------------------------------------------------------------------
# Cycles

sub Graph_is_cycle {
  my ($graph, $aref) = @_;
  foreach my $i (0 .. $#$aref) {
    $graph->has_edge($aref->[$i], $aref->[$i-1]) or return 0;
  }
  return 1;
}

# $graph is a Graph.pm.  Find all cycles in it.
# The return is a list of arrayrefs, with each arrayref containing vertices
# which are a cycle.
# Each cycle appears just once, so just one direction around, not both ways.
#
# The order of vertices within each cycle and the order of cycles in the
# return are both unspecified.  Within each cycle has a canonical order, but
# don't rely on that.  The order of cycles is hash-random.
#
sub Graph_find_all_cycles {
  my ($graph) = @_;
  my @paths = map {[$_]} $graph->vertices;
  my @cycles;
  while (@paths) {
    ### num paths: scalar @paths
    my @new_paths;
    foreach my $path (@paths) {
    NEIGHBOUR: foreach my $next ($graph->neighbours($path->[-1])) {
        next if $next lt $path->[0];  # must have start smallest
        if ($next eq $path->[0]) { # back to start, len=1 or >=3
          Graph_is_cycle($graph, $path) or die;
          if (@$path!=2
              && $path->[1] lt $path->[-1]) { # direction smaller second only
            push @cycles, $path;
          }
        } else {
          foreach my $i (1 .. $#$path) {
            next NEIGHBOUR if $next eq $path->[$i];  # back to non-start
          }
          push @new_paths, [ @$path, $next ];
        }
      }
    }
    @paths = @new_paths;
  }
  return @cycles;
}
sub Graph_num_cycles {
  my ($graph) = @_;
  my @cycles = Graph_find_all_cycles($graph);
  return scalar @cycles;
}

# Return true if $graph has a bi-cyclic component, meaning a connected
# component with 2 or more cycles in it.
sub Graph_has_bicyclic_component {
  my ($graph) = @_;
  my @components = $graph->connected_components;
  foreach my $component (@components) {
    my $subgraph = $graph->subgraph($component);
    if (MyGraphs::Graph_num_cycles($subgraph) >= 2) {
      return 1;
    }
  }
  return 0;
}


# length of the smallest cycle in $graph
sub Graph_girth {
  my ($graph) = @_;
  ### Graph_girth() ...
  my $num_vertices = scalar $graph->vertices;
  my $girth;
  my $min = $graph->is_directed ? 1 : 3;
 OUTER: foreach my $from ($graph->vertices) {
    ### $from
    my %seen = ($from => 1);
    my @pending = ($from);
    foreach my $len (1 .. ($girth||$num_vertices)) {
      ### at: "len=$len pending=".join('  ',@pending)
      my @new_pending;
      foreach my $to (map {$graph->successors($_)} @pending) {
        if ($len>=$min && $to eq $from) {
          ### cycle: "to=$to len=$len"
          if (!defined $girth || $len < $girth) {
            ### is new low ...
            $girth = $len;
          }
          next OUTER;
        }
        unless ($seen{$to}++) {
          push @new_pending, $to;
        }
      }
      @pending = @new_pending;
    }
  }
  return $girth;
}


# $graph is an undirected Graph.pm.
# If $v is in a hanging cycle, other than the attachment point, then return
# an arrayref of the vertices of that cycle other than the attachment point
# (in an unspecified order).
# For example,
#
#            4---5
#             \ /
#      1---2---3---6
#
# has hanging cycle 3,4,5.  $v=4 or $v=5 gives return is [4,5].
# If $v is not in a hanging cycle then return undef.
#
sub Graph_is_hanging_cycle {
  my ($graph, $v) = @_;
  if ($graph->degree($v) != 2) { return undef; }

  my %cycle = ($v => 1);
  my @pending = $graph->neighbours($v);
  my @end;
  while (@pending) {
    $v = pop @pending;
    next if $cycle{$v};
    if ($graph->degree($v) != 2) {
      push @end, $v;
      next;
    }
    $cycle{$v} = 1;
    push @pending, $graph->neighbours($v);
  }
  if (@end == 0 || (@end==2 && $end[0] eq $end[1])) {
    return [ keys %cycle ];
  } else {
    return undef;
  }
}

# $graph is an undirected Graph.pm.
# Modify $graph to remove any hanging cycles.
# For example,
#
#            4---5
#             \ /
#      1---2---3---6
#
# has hanging cycle 3,4,5.  Vertices 4,5 are removed.
#
sub Graph_delete_hanging_cycles {
  my ($graph) = @_;
  my $count = 0;
 MORE: for (;;) {
    foreach my $v ($graph->vertices) {
      if (my $aref = Graph_is_hanging_cycle($graph,$v)) {
        $graph->delete_vertices(@$aref);
        $count++;
        next MORE;
      }
    }
    last;
  }

  if ($count
      && defined(my $name = $graph->get_graph_attribute('name'))) {
    $graph->set_graph_attribute (name => "$name, stripped hanging");
  }
  return $count;
}

#   d-----c
#   |     |
#   a-----b
sub Graph_find_all_4cycles {
  my ($graph, %options) = @_;
  ### Graph_find_all_4cycles() ...
  my $callback = $options{'callback'} || sub{};

  my %seen;
  foreach my $a (sort $graph->vertices) {
    my @a_neighbours = $graph->neighbours($a);
    ### a: "$a  to ".join(',',@a_neighbours)

    foreach my $b (@a_neighbours) {
      next if $b eq $a;  # ignore self-loops
      my @b_neighbours = $graph->neighbours($b);
      if (! $graph->has_edge($a,$b)) {
        print " a=$a\n";
        foreach my $neighbour (@a_neighbours) {
          print "  $neighbour\n";
        }
        die "oops, no edge $a to $b";
      }

      foreach my $c (@b_neighbours) {
        next if $c eq $a;
        next if $c eq $b;
        my @c_neighbours = $graph->neighbours($c);
        if (! $graph->has_edge($b,$c)) {
          die "oops";
        }

        foreach my $d (@c_neighbours) {
          if (! $graph->has_edge($c,$d)) {
            die "oops";
          }
          next if $d eq $a;
          next if $d eq $b;
          next if $d eq $c;
        my @d_neighbours = $graph->neighbours($d);
          ### $d
          ### cycle: "$a  $b  $c  $d  goes ".join(',',@d_neighbours)
          next unless $graph->has_edge($d,$a) || $graph->has_edge($a,$d);

          next if $seen{$a,$b,$c,$d}++;
          next if $seen{$b,$c,$d,$a}++;
          next if $seen{$c,$d,$a,$b}++;
          next if $seen{$d,$a,$b,$c}++;

          next if $seen{$d,$c,$b,$a}++;
          next if $seen{$c,$b,$a,$d}++;
          next if $seen{$b,$a,$d,$c}++;
          next if $seen{$a,$d,$c,$b}++;

          # print "raw ",join(' -- ',($a,$b,$c,$d)),"\n";
          # print "  has_edge ",$graph->has_edge($a,$b),"\n";
          # print "  has_edge ",$graph->has_edge($b,$c),"\n";
          # print "  has_edge ",$graph->has_edge($c,$d),"\n";
          # print "  has_edge ad ",$graph->has_edge($d,$a),"\n";

          # must not mutate the loop variables $a,$b,$c,$d, so @cycle
          my @cycle = ($a,$b,$c,$d);
          my $min = minstr(@cycle);
          while ($cycle[0] ne $min) {  # rotate to $cycle[0] the minimum
            push @cycle, (shift @cycle);
          }
          $callback->(@cycle);
        }
      }
    }
  }
  return;
}


#------------------------------------------------------------------------------
# Euler Cycle

# Return a list of vertices v1,v2,...,vn,v1 which is an Euler cycle, so
# traverse each edge exactly once.
#
sub Graph_Euler_cycle {
  my ($graph, %options) = @_;
  my $type = $options{'type'} || 'cycle';
  ### $type
  my @vertices = $graph->vertices;
  my $func = cmp_func(@vertices);
  @vertices = sort $func @vertices;
  my @edges = $graph->edges;
  my $num_edges = scalar(@edges);
  my @edge_keys = map {join(' to ',@$_)} @edges;
  my %edge_keys = map { my $key = join(' to ',@$_);
                        ($key => $key,
                         join(' to ',reverse @$_) => $key)
                      } @edges;
  my %neighbours;
  foreach my $v (@vertices) {
    $neighbours{$v} = [ sort $func $graph->neighbours($v) ];
  }

  my @path = $vertices[0];
  my $try;
  $try = sub {
    my ($visited) = @_;
    if (scalar(keys %$visited) >= $num_edges) {
      return 1;
    }
    my $v = $path[-1];
    foreach my $to (@{$neighbours{$v}}) {
      my $edge = $edge_keys{"$v to $to"};
      next if $visited->{$edge};
      push @path, $to;
      if ($try->({ %$visited, $edge => 1 })) {
        return 1;
      }
      pop @path;
    }
    return 0;
  };
  if ($try->({})) {
    return @path;
  } else {
    return;
  }

  # my @path;
  # my %visited;
  # my $v = $vertices[0];
  # my @nn = (-1);
  # my $upto = 0;
  # for (;;) {
  #   my $v = $path[$upto];
  #   my $n = ++$nn[$upto];
  #   my $to = $neighbours{$v}->[$n];
  #   ### at: join('--',@path) . " upto=$upto v=$v n=$n"
  #   ### $to
  #   ### assert: 0 <= $n && $n <= $#{$neighbours{$v}}+1
  #   if (! defined $to) {
  #     ### no more neighbours, backtrack ...
  #     $visited{$v} = 0;
  #     $upto--;
  #     last if $upto < 0;
  #     next;
  #   }
  #   if ($visited{$to}) {
  #     ### to is visited ...
  #     if ($upto == $num_vertices-1
  #         && ($type eq 'path'
  #             || $to eq $path[0])) {
  #       ### found path or cycle ...
  #       if ($options{'verbose'}) { print "found ",join(',',@path),"\n"; }
  #       if ($options{'found_coderef'}) { $options{'found_coderef'}->(@path); }
  #       if (! $options{'all'}) { return 1; }
  #     }
  #     next;
  #   }
  #
  #   # extend path to $to
  #   $upto++;
  #   $path[$upto] = $to;
  #   $visited{$to} = 1;
  #   $nn[$upto] = -1;
  # }
}

#------------------------------------------------------------------------------
# Hamiltonian Cycle

# $graph is a Graph.pm.
# Return true if it has a Hamiltonian cycle (a cycle visiting all vertices
# once each).  Key/value options are
#
#     type => "cycle" or "path" (default "cycle")
#
# type "path" means search for a Hamiltonian path (a path visiting all
# vertices once each).
#
# Currently this is a depth first search so quite slow and suitable only for
# a small number of vertices.
#
sub Graph_is_Hamiltonian {
  my ($graph, %options) = @_;
  my $type = $options{'type'} || 'cycle';
  ### $type

  my @vertices = $graph->vertices;
  my $num_vertices = scalar(@vertices);
  my %neighbours;
  foreach my $v (@vertices) {
    $neighbours{$v} = [ $graph->neighbours($v) ];
  }

  foreach my $start (defined $options{'start'} ? $options{'start'}
                     : $type eq 'path' ? @vertices
                     : $vertices[0]) {
    if ($options{'verbose'}) { print "try start $start\n"; }
    my @path = ($start);
    my %visited = ($path[0] => 1);
    my @nn = (-1);
    my $upto = 0;
    for (;;) {
      my $v = $path[$upto];
      my $n = ++$nn[$upto];
      my $to = $neighbours{$v}->[$n];
      ### at: join('--',@path) . " upto=$upto v=$v n=$n"
      ### $to
      ### assert: 0 <= $n && $n <= $#{$neighbours{$v}}+1
      if (! defined $to) {
        ### no more neighbours, backtrack ...
        $visited{$v} = 0;
        $upto--;
        last if $upto < 0;
        next;
      }
      if ($visited{$to}) {
        ### to is visited ...
        if ($upto == $num_vertices-1
            && ($type eq 'path'
                || $to eq $path[0])) {
          ### found path or cycle ...
          if ($options{'verbose'}) { print "found ",join(',',@path),"\n"; }
          if ($options{'found_coderef'}) { $options{'found_coderef'}->(@path); }
          if (! $options{'all'}) { return 1; }
        }
        next;
      }

      # extend path to $to
      $upto++;
      $path[$upto] = $to;
      $visited{$to} = 1;
      $nn[$upto] = -1;
    }
  }
  return 0;
}


#------------------------------------------------------------------------------
# Directed Graphs

# $graph is a directed Graph.pm.
# Return the number of maximal paths.
# A maximal path is from a predecessorless to a successorless.
# There might be multiple paths between a given predecessorless and
# successorless.  All such paths are counted.
#
sub Graph_num_maximal_paths {
  my ($graph) = @_;
  ### Graph_num_maximal_paths() ...
  $graph->expect_directed;

  my %indegree_remaining;
  my %ways;
  my %pending;
  foreach my $v ($graph->vertices) {
    $pending{$v} = 1;
    if ($indegree_remaining{$v} = $graph->in_degree($v)) {
      $ways{$v} = 0;
    } else {
      $ways{$v} = 1;
    }
  }

  my $ret = 0;
  while (%pending) {
    ### at pending: scalar(keys %pending)
    my $progress;
    foreach my $v (keys %pending) {
      if ($indegree_remaining{$v}) {
        ### not ready: "$v  indegree_remaining $indegree_remaining{$v}"
        ### assert: $indegree_remaining{$v} >= 0
        next;
      }
      delete $pending{$v};
      my @successors = $graph->successors($v);
      if (@successors) {
        foreach my $to (@successors) {
          ### edge: "$v to $to  countedge ".$graph->get_edge_count($v,$to)
          $pending{$to} or die "oops, to=$to not pending";
          $ways{$to} += $ways{$v} * $graph->get_edge_count($v,$to);
          $indegree_remaining{$to}--;
          $progress = 1;
        }
      } else {
        # successorless
        $ret += $ways{$v};
      }
    }
    if (%pending && !$progress) {
      die "Graph_num_maximal_paths() oops, no progress, circular graph";
    }
  }
  return $ret;
}


#------------------------------------------------------------------------------
# Lattices

# $graph is a directed Graph.pm.
# Return the number of pairs of comparable elements $u,$v, meaning pairs
# where there is a path from $u to $v.  The count includes $u,$u empty path.
# For a lattice graph, this is the number of "intervals" in the lattice.
#
sub Graph_num_intervals {
  my ($graph) = @_;
  my $ret = 0;
  foreach my $v ($graph->vertices) {
    $ret += 1 + $graph->all_successors($v);
  }
  return $ret;
}

sub Graph_successors_matrix {
  my ($graph, $vertices_aref, $vertex_to_index_href) = @_;
  ### $vertices_aref
  ### $vertex_to_index_href
  my @ret;
  foreach my $i_from (0 .. $#$vertices_aref) {
    foreach my $to ($graph->successors($vertices_aref->[$i_from])) {
      my $i_to = $vertex_to_index_href->{$to}
        // die "oops, not found: $to";
      $ret[$i_from]->[$i_to] = 1;
    }
  }
  return \@ret;
}
sub Graph_reachable_matrix {
  my ($graph, $vertices_aref, $vertex_to_index_href) = @_;
  my $ret
    = Graph_successors_matrix($graph,$vertices_aref,$vertex_to_index_href);
  foreach my $i (0 .. $#$vertices_aref) {
    $ret->[$i]->[$i] = 1;
  }
  my $more = 1;
  while ($more) {
    $more = 0;
    foreach my $i (0 .. $#$vertices_aref) {
      foreach my $j (0 .. $#$vertices_aref) {
        foreach my $k (0 .. $#$vertices_aref) {
          if ($ret->[$i]->[$j] && $ret->[$j]->[$k]
              && ! $ret->[$i]->[$k]) {
            $ret->[$i]->[$k] = 1;
            $more = 1;
          }
        }
      }
    }
  }
  return $ret;
}

# $graph is a directed Graph.pm which is a lattice.
# Return its "intervals lattice".
#
# An interval is a pair [$x,$y] with $y reachable from $x.
# Each vertex of the intervals lattice is such an interval, in the form of a
# string "$x-$y".  Edges are from "$x-$y" to "$u-$v" where $x < $u and $y < $v,
# where < means $u reachable from $x, and $v reachable from $y.
#
sub Graph_make_intervals_lattice {
  my ($graph, $covers) = @_;
  $graph->expect_directed;
  my $intervals = Graph->new;

  my @vertices = $graph->vertices;
  my %vertex_to_index;
  @vertex_to_index{@vertices} = (0 .. $#vertices);

  my $graph_reachable
    = Graph_reachable_matrix($graph, \@vertices, \%vertex_to_index);
  ### $graph_reachable

  sum(map{sum(map {$_||0} @$_)} @$graph_reachable) == Graph_num_intervals($graph) or die;

  my %intervals;
  foreach my $a (0 .. $#vertices) {
    foreach my $b (0 .. $#vertices) {
      next unless $graph_reachable->[$a]->[$b];
      my $from = "$vertices[$a]-$vertices[$b]";
      $intervals->add_vertex($from);
      $intervals{$from} = [$a,$b];
    }
  }

  foreach my $from (keys %intervals) {
    my $from_aref = $intervals{$from};
    foreach my $to (keys %intervals) {
      next if $to eq $from;
      my $to_aref = $intervals{$to};
      next unless $graph_reachable->[$from_aref->[0]]->[$to_aref->[0]];
      next unless $graph_reachable->[$from_aref->[1]]->[$to_aref->[1]];
      ### $from
      ### $to
      # print "$a $b   $c $d\n";
      # next if $covers && defined $intervals->path_length($from,$to);
      $intervals->add_edge($from, $to);
    }
  }
  return $covers ? Graph_covers($intervals) : $intervals;


  # $graph->expect_directed;
  # my $intervals = Graph->new;
  # foreach my $a ($graph->vertices) {
  #   foreach my $b ($graph->vertices) {
  #     next unless defined $graph->path_length($a,$b);
  #     my $from = "$a -- $b";
  #
  #     foreach my $c ($graph->vertices) {
  #       next unless defined $graph->path_length($a,$c);
  #       foreach my $d ($graph->vertices) {
  #         next unless defined $graph->path_length($c,$d);
  #         next unless defined $graph->path_length($b,$d);
  #         my $to = "$c -- $d";
  #         next if $to eq $from;
  #         # print "$a $b   $c $d\n";
  #         next if $covers && defined $intervals->path_length($from,$to);
  #         $intervals->add_edge($from, $to);
  #       }
  #     }
  #   }
  # }
  # return $covers ? Graph_covers($intervals) : $intervals;
}

# $graph is a directed Graph.pm which is expected to be acyclic.
# Delete edges to leave just its cover relations.
#
# At some from->to, if there is also from->mid->to then edge from->to is not
# a cover and is deleted.
#
sub Graph_covers {
  my ($graph) = @_;

  $graph->expect_acyclic;
  my @vertices = $graph->vertices;
  my %vertex_to_index;
  @vertex_to_index{@vertices} = (0 .. $#vertices);

  my $reachable
    = Graph_reachable_matrix($graph, \@vertices, \%vertex_to_index);

  foreach my $from (0 .. $#vertices) {
    foreach my $mid (0 .. $#vertices) {
      next if $from == $mid;
      next unless $reachable->[$from]->[$mid];

      foreach my $to (0 .. $#vertices) {
        next if $mid == $to;
        next unless $reachable->[$mid]->[$to];
        $graph->delete_edge($vertices[$from],$vertices[$to]);
      }
    }
  }
  return $graph;
}

# $graph is a directed Graph.pm which is expected to be a lattice.
# Return its unique lowest element.
sub Graph_lattice_lowest {
  my ($graph) = @_;
  my @predecessorless = $graph->predecessorless_vertices;
  @predecessorless==1
    or die "Graph_lattice_lowest() oops, expected one predecessorless";
  return $predecessorless[0];
}

# $graph is a directed Graph.pm which is expected to be a lattice.
# Return its unique highest element.
sub Graph_lattice_highest {
  my ($graph) = @_;
  my @successorless = $graph->successorless_vertices;
  @successorless==1
    or die "Graph_lattice_highest() oops, expected one successorless";
  return $successorless[0];
}

# $graph is a directed Graph.pm which is expected to be a lattice.
# Return $href where
#     $href->{'max'}->{$x}->{$y}  is the lattice max($x,y)
#     $href->{'min'}->{$x}->{$y}  is the lattice min($x,y)
#
sub Graph_lattice_minmax_hash {
  my ($graph) = @_;
  my $verbose = 1;
  my %hash;
  my @vertices = $graph->vertices;
  foreach my $elem (['all_successors','max'],
                    ['all_predecessors','min']) {
    my ($all_method, $key) = @$elem;

    # $all_successors{$x}->{$y} = boolean, true x has y after it, false if not.
    # x is a successor of itself ($graph->all_successors doesn't include x
    # itself).
    my %all_successors;
    foreach my $x (@vertices) {
      $all_successors{$x}->{$x} = 1;
      foreach my $s ($graph->$all_method($x)) {
        $all_successors{$x}->{$s} = 1;
      }
    }

    # For each pair x,y look at the common successors and choose the smallest.
    # Smallest in the sense the smaller has bigger among its successors.
    foreach my $x (@vertices) {
      my $xs_href = $all_successors{$x};
      foreach my $y (@vertices) {
        my $ys_href = $all_successors{$y};
        my $m;
        foreach my $xs (keys %$xs_href) {
          if ($ys_href->{$xs}) {  # common successor
            if (!defined $m || $all_successors{$xs}->{$m}) {
              $m = $xs;           # which is before best $m so far
            }
          }
        }
        $hash{$key}->{$x}->{$y} = $m;
      }
    }
  }
  return \%hash;


  # foreach my $v (@vertices) {
  #   $hash{'max'}->{$v}->{$v}
  #     = $hash{'min'}->{$v}->{$v} = $v;
  # }
  # foreach my $x (@vertices) {
  #   foreach my $y ($graph->all_successors($x)) {
  #     $hash{'max'}->{$x}->{$y}
  #       = $hash{'max'}->{$y}->{$x}  = $y;
  #     if ($verbose) { print "successor  $x max $y = $y\n"; }
  #   }
  #   foreach my $y ($graph->all_predecessors($x)) {
  #     $hash{'min'}->{$x}->{$y}
  #       = $hash{'min'}->{$y}->{$x}  = $y;
  #     if ($verbose) { print "predecessor  $x min $y = $y\n"; }
  #   }
  # }

  # my $more = 1;
  # while ($more) {
  #   $more = 0;
  #   foreach my $M ('min','max') {
  #     foreach my $x (@vertices) {
  #       foreach my $y (@vertices) {
  #         if (defined(my $m $hash{$M}->{$x}->{$y})) {
  #           foreach my $z (@vertices) {
  #
  #             if (defined(my $m = $hash{'max'}->{$y}->{$z})) {
  #             $more = 1;
  #             $hash{'max'}->{$x}->{$y}
  #               = $hash{'max'}->{$y}->{$x}
  #               = $m;
  #             if ($verbose) { print "chain  $x max $y = $m  from $z\n"; }
  #           }
  #         }
  #       }
  #       if (! defined $hash{'min'}->{$x}->{$y}) {
  #         foreach my $z ($graph->predecessors($y)) {
  #           if (defined(my $m = $hash{'min'}->{$x}->{$z})) {
  #             $more = 1;
  #             $hash{'min'}->{$x}->{$y}
  #               = $hash{'min'}->{$y}->{$x}
  #               = $m;
  #             if ($verbose) { print "chain  $x min $y = $m  from $z\n"; }
  #           }
  #         }
  #       }
  #     }
  #   }
  # }

  # my $more = 1;
  # while ($more) {
  #   $more = 0;
  #   foreach my $x (@vertices) {
  #     foreach my $y (@vertices) {
  #       if (! defined $hash{'max'}->{$x}->{$y}) {
  #         foreach my $z ($graph->successors($y)) {
  #           if (defined(my $m = $hash{'max'}->{$x}->{$z})) {
  #             $more = 1;
  #             $hash{'max'}->{$x}->{$y}
  #               = $hash{'max'}->{$y}->{$x}
  #               = $m;
  #             if ($verbose) { print "chain  $x max $y = $m  from $z\n"; }
  #           }
  #         }
  #       }
  #       if (! defined $hash{'min'}->{$x}->{$y}) {
  #         foreach my $z ($graph->predecessors($y)) {
  #           if (defined(my $m = $hash{'min'}->{$x}->{$z})) {
  #             $more = 1;
  #             $hash{'min'}->{$x}->{$y}
  #               = $hash{'min'}->{$y}->{$x}
  #               = $m;
  #             if ($verbose) { print "chain  $x min $y = $m  from $z\n"; }
  #           }
  #         }
  #       }
  #     }
  #   }
  # }
  #
  # return \%hash;
}

# $graph is a directed Graph.pm which is expected to be a lattice.
# $href is a hashref as returned by Graph_lattice_minmax_hash().
# Check that the relations in $href follow the lattice rules.
# die() if bad.
#
sub Graph_lattice_minmax_validate {
  my ($graph, $href) = @_;
  my $str = Graph_lattice_minmax_reason($graph,$href);
  if ($str) {
    die 'Graph_lattice_minmax_validate() ', $str;
  }
}

# $graph is a directed Graph.pm which is expected to be a lattice.
# $href is a hashref as returned by Graph_lattice_minmax_hash().
# Check that the relations in $href follow the lattice rules.
# If good then return empty string ''.
# If bad then return a string describing the problem.
#
sub Graph_lattice_minmax_reason {
  my ($graph, $href) = @_;

  # defined
  foreach my $x ($graph->vertices) {
    foreach my $y ($graph->vertices) {
      foreach my $M ('min','max') {
        defined $href->{$M}->{$x}->{$y}
          or return "missing $x $M $y";
      }
    }
  }

  # commutative
  foreach my $x ($graph->vertices) {
    foreach my $y ($graph->vertices) {
      foreach my $M ('min','max') {
        $href->{$M}->{$x}->{$y}  eq $href->{$M}->{$y}->{$x}
          or return "not commutative $x $M $y";
      }
    }
  }

  # idempotent
  foreach my $x ($graph->vertices) {
    foreach my $y ($graph->vertices) {
      foreach my $M ('min','max') {
        my $m = $href->{$M}->{$x}->{$y};
        $href->{$M}->{$x}->{$m} eq $m
          or return "not idempotent $x $M $y";
      }
    }
  }

  # absorptive a ^ (a v b) = a v (a ^ b) = a
  #                   L             H
  foreach my $x ($graph->vertices) {
    foreach my $y ($graph->vertices) {
      my $min = $href->{'min'}->{$x}->{$y};
      my $max = $href->{'max'}->{$x}->{$y};
      my $a = $href->{'max'}->{$x}->{$min};
      my $b = $href->{'min'}->{$x}->{$max};
      ($a eq $x && $b eq $x)
        or return "not absorptive $x and $y min $min max $max got $a and $b";
    }
  }

  # associative  (xy)z = x(yz)
  foreach my $x ($graph->vertices) {
    foreach my $y ($graph->vertices) {
      foreach my $z ($graph->vertices) {
        foreach my $M ('min','max') {
          my $a = $href->{$M}->{$href->{$M}->{$x}->{$y}}->{$z};
          my $b = $href->{$M}->{$x}->{$href->{$M}->{$y}->{$z}};
          $a eq $b
            or return "not associative $x $M $y $M $z got $a and $b";
        }
      }
    }
  }
  return '';
}

# $graph is a directed Graph.pm which is a lattice.
# $href is a hashref as returned by Graph_lattice_minmax_hash().
# Return true if $graph is semi-distributive.
#
sub lattice_minmax_is_semidistributive {
  my ($graph, $href) = @_;
  foreach my $x ($graph->vertices) {
    foreach my $y ($graph->vertices) {
      my $m = $href->{'min'}->{$x}->{$y};
      my $M = $href->{'max'}->{$x}->{$y};
      foreach my $z ($graph->vertices) {
        if ($m eq $href->{'min'}->{$x}->{$z}) {
          $href->{'min'}->{$x}->{$href->{'max'}->{$y}->{$z}} eq $m
            or return 0;
        }
        if ($M eq $href->{'max'}->{$x}->{$z}) {
          $href->{'max'}->{$x}->{$href->{'min'}->{$y}->{$z}} eq $M
            or return 0;
        }
      }
    }
  }
}

# $graph is a directed Graph.pm which is a lattice.
# $href is a hashref as returned by Graph_lattice_minmax_hash().
# Return the number of complementary pairs in $graph.
# A complementary pair is vertices u,v where
#    min(u,v) = global min   and   max(u,v) = global max
# so they neither meet nor join other than the global min,max.
#
# u = global min and v = global max is always a complementary pair.
# If the lattice is just 1 vertex then this includes u=v as a pair.
#
sub lattice_minmax_num_complementary_pairs {
  my ($graph, $href) = @_;
  my $lowest = MyGraphs::Graph_lattice_lowest($graph);
  my $highest = MyGraphs::Graph_lattice_highest($graph);
  my @vertices = $graph->vertices;
  my $count_complementary = 0;
  foreach my $i (0 .. $#vertices) {
    my $u = $vertices[$i];
    foreach my $j ($i .. $#vertices) {
      my $v = $vertices[$j];
      my $min = $href->{'min'}->{$u}->{$v};
      my $max = $href->{'max'}->{$u}->{$v};
      $count_complementary += ($min eq $lowest && $max eq $highest);
    }
  }
  return $count_complementary;
}


# Think not efficient to check pair-by-pair.
#
# # Return true if $u and $v are complementary, meaning their min is the
# # bottom element and max is the top element.
# sub lattice_is_complementary {
#   my ($graph, $u,$v) = @_;
#   return lattice_min($graph, $u,$v) eq Graph_lattice_lowest($graph)
#     &&   lattice_max($graph, $u,$v) eq Graph_lattice_highest($graph);
# }

# Is it efficient to search lattice min(x,y) or max(x,y), or better always
# build whole table?
#
# sub lattice_min {
#   my ($graph, $u, $v) = @_;
#   return lattice_min_or_max($graph,$u,$v, 'predecessors', 'all_predecessors');
# }
# sub lattice_max {
#   my ($graph, $u, $v) = @_;
#   return lattice_min_or_max($graph,$u,$v, 'successors', 'all_successors');
# }
# sub lattice_min_or_max {
#   my ($graph, $u, $v, $immediate, $all) = @_;
#
#   die "WRONG";
#
#   my @verts = ($u,$v);
#   my @verts_descendants;
#   foreach my $i (0,1) {
#     $verts_descendants[$i]->[0]->{$verts[$i]} = 1;
#   }
#   for (my $distance = 0; ; $distance++) {
#     foreach my $i (0,1) {
#       foreach my $from (keys %{$verts_descendants[$i]->[$distance]}) {
#         foreach my $to_distance (0 .. $distance) {
#           if ($verts_descendants[!$i]->[$to_distance]->{$from}) {
#             return $from;
#           }
#         }
#       }
#     }
#     foreach my $i (0,1) {
#       $verts_descendants[$i]->[$distance+1]
#         = graph_following_set_hashref($graph,$immediate,
#                                       $verts_descendants[$i]->[$distance]);
#     }
#     if (! $verts_descendants[0]->[$distance+1]
#         && ! $verts_descendants[1]->[$distance+1]) {
#       die "lattice_min_or_max() not found";
#     }
#   }
#
#   # my %v_successors; @v_successors{$v, $graph->$all($v)} = ();  # hash slice
#   # my %t = ($u => 1);
#   # while (%t) {
#   #   foreach my $t (keys %t) {
#   #     if (exists $v_successors{$t}) {
#   #       return $t;
#   #     }
#   #   }
#   #   my %new_t;
#   #   foreach my $t (keys %t) {
#   #     @new_t{$graph->$immediate($t)} = ();  # hash slice
#   #   }
#   #   %t = %new_t;
#   # }
#   # die "lattice_min_or_max() not found";
# }
# sub graph_following_set_hashref {
#   my ($graph, $method, $href) = @_;
#   my %ret;
#   foreach my $v (keys %$href) {
#     @ret{$graph->$method($v)} = ();  # hash slice
#   }
#   return \%ret;
# }


#------------------------------------------------------------------------------
1;
__END__
