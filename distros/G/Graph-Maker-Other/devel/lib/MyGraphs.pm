# Copyright 2015, 2016, 2017 Kevin Hyde
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


package MyGraphs;
use 5.010;
use strict;
use warnings;
use Carp 'croak';
use List::Util 'min','max','sum','minstr';
use Scalar::Util 'blessed';
use File::Spec;
use File::HomeDir;
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
              'Graph_has_claw',
              'Graph_clique_number',
              'Graph_width_list',
              'Graph_find_all_4cycles',
              'Graph_rename_vertex','Graph_pad_degree',
              'Graph_eccentricity_path',
              'Graph_tree_centre_vertices',

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
              'hog_searches_html',
              'postscript_view_file',

              'Graph_to_GraphViz2',
              'Graph_strip_hanging_cycles',

              'Graph_subtree_depth',
              'Graph_subtree_children',

              'Graph_is_Hamiltonian',

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
  my @command = ('gv','--scale=.4',$filename);
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

  graphviz_view_file($dot_filename);
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
  IPC::Run::run(['dot','-Tps'], '<',$filename, '>',$ps_filename);
  # IPC::Run::run(['neato','-Tps','-s2'], '<',$filename, '>',$ps_filename);

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
  my ($graph, $v) = @_;
  my @children = grep {$_ > $v} $graph->neighbours($v);
  return @children;
}
sub Graph_vertex_num_children {
  my ($graph, $v) = @_;
  return scalar(grep {$_ > $v} $graph->neighbours($v));
}

# $graph is a Graph.pm, show it graphically
#   synchronous => 1, wait for viewer to exit before returning.
#   xy => 1, treat each vertex name as x,y coordinates
sub Graph_view {
  my ($graph, %options) = @_;
  ### Graph_view(): %options
  $options{'vertex_name_type'}
    //= $graph->get_graph_attribute('vertex_name_type')
    // ($graph->get_graph_attribute('xy') ? 'xy' : undef)
    // '';
  if ($options{'vertex_name_type'} =~ /^xy/) {
    my $graphviz2 = Graph_to_GraphViz2($graph, %options);
    GraphViz2_view($graphviz2, driver=>'neato', %options);
    return;
  }

  require Graph::Convert;
  my $easy = Graph::Convert->as_graph_easy($graph);
  $easy->set_attribute('flow','south');
  if (defined(my $name = $graph->get_graph_attribute('name'))) {
    $easy->set_attribute('label',$name);
  }
  Graph_Easy_view($easy, %options);
  # print "Graph: ", $graph->is_directed ? "directed\n" : "undirected\n";
  # print "Easy:  ", $easy->is_directed ? "directed\n" : "undirected\n";
}

sub Graph_vertex_parent {
  my ($graph, $v) = @_;
  my @parents = grep {$_ < $v} $graph->neighbours($v);
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
  if ($graph->has_vertex(0)) {
    return 0;
  }
  if ($graph->has_vertex(1)) {
    return 1;
  }
  croak "No tree root found";
}

sub Graph_tree_height {
  my ($graph, $root) = @_;
  $root //= Graph_tree_root($graph);
  ### $root
  my $height = 0;
  my @pending = ([$root, $root]);
  my $pos = 0;
  while ($pos >= 0) {
    ### at: "pos=$pos ".join(',',map {$pending[$_]->[0]} 0 .. $pos)
    if ($pos > $height) {
      $height = $pos;
      ### $height
    }
    my $aref = $pending[$pos];
    if (@$aref < 2) {
      $pos--;
      next;
    }
    my $v = pop @$aref;
    my @neighbours = $graph->neighbours($v);
    my $parent = $pending[$pos]->[0];
    @neighbours = grep {$_ ne $parent} @neighbours;
    ### @neighbours
    if (@neighbours) {
      @{$pending[++$pos]} = ($v, @neighbours);
    }
  }
  return $height;
}

# Return a list of arrayrefs [$v,$v,...] which are the vertices at
# successive depths of tree $graph.  The first arrayref contains the tree root.
sub Graph_vertices_by_depth {
  my ($graph, %options) = @_;
  my $root = $options{'root'} // Graph_tree_root($graph);
  my @ret = ([$root]);
  my $cmp = $options{'cmp'} || \&cmp_numeric;
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

    my $cmp = $options{'cmp'} || \&cmp_numeric;
    my @vertices = $graph->vertices;
    my @vertices_by_depth = Graph_vertices_by_depth($graph, cmp => $cmp);
    my @column;
    my @children;

    foreach my $v (@vertices) {
      $children[$v] = [ sort $cmp Graph_vertex_children($graph,$v) ];
      $column[$v] = 0;
    }

    my $more;
    do {
      $more = 0;

      # no overlaps within row
      foreach my $depth (0 .. $#vertices_by_depth) {
        my $aref = $vertices_by_depth[$depth];
        foreach my $i (1 .. $#$aref) {
          my $v1 = $aref->[$i-1];
          my $v2 = $aref->[$i];
          my $c = $column[$v1] + length($v1)
            + (Graph_vertex_parent($graph,$v1)
               eq Graph_vertex_parent($graph,$v2)
               ? $sibling_gap : $gap);
          if ($column[$v2] < $c) {
            $column[$v2] = $c;
            $more = 1;
          }
        }
      }

      # parent half-way along children,
      # or children moved up if parent further along
      foreach my $v (@vertices) {
        my $children_aref = $children[$v];
        next unless @$children_aref;
        my $min = $column[$children_aref->[0]];
        my $max = $column[$children_aref->[-1]] + length($children_aref->[-1]);
        my $c = int(($max + $min - length($v))/2);
        if ($column[$v] < $c) {
          $column[$v] = $c;
          $more = 1;
        } elsif ($column[$v] > $c) {
          $column[$children_aref->[0]]++;
          $more = 1;
        }
      }

      # leading leaf child moves up to its sibling
      foreach my $parent (@vertices) {
        my $children_aref = $children[$parent];
        my $v1 = $children_aref->[0] // next;
        my $v2 = $children_aref->[1] // next;
        next if @{$children[$v1]}; # want $v1 leaf
        my $c = $column[$v2] - length($v1) - $sibling_gap;
        if ($column[$v1] < $c) {
          $column[$v1] = $c;
          $more = 1;
        }
      }

    } while ($more);

    my $total_column = max(map {$column[$_]+length($_)} @vertices) + 3;
    my @lines;
    foreach my $depth (0 .. $#vertices_by_depth) {
      my $aref = $vertices_by_depth[$depth];
      my $c = 0;
      my $line = '';
      foreach my $v (@$aref) {
        $column[$v] ||= 0;
        while ($c < ($column[$v]||0)) {
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
          my $children_aref = $children[$v];
          next unless @$children_aref;
          my $min = $column[$children_aref->[0]];
          my $max = $column[$children_aref->[-1]] + length($children_aref->[-1]);

          if (@$children_aref > 1) {
            if (length($children_aref->[0]) > 1) { $min++; }
            if (length($children_aref->[-1]) > 1) { $max--; }
          }

          my $mid = int($column[$v] + length($v)/2);
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

  print "     ";
  foreach my $x ($x_min .. $x_max) {
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

# hog_searches_html($graph,$graph,...)
# Create a /tmp/hog-searches.html of forms to search hog for each $graph.
# Each $graph is either Graph.pm or Graph::Easy.
#
sub hog_searches_html {
  my @graphs = @_;

  my $html_filename = '/tmp/hog-searches.html';
  my $hog_url = 'https://hog.grinvin.org';
  # $hog_url = 'http://localhost:10000';

  open my $h, '>', $html_filename or die;
  print $h <<'HERE';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<body>
HERE

  foreach my $i (0 .. $#graphs) {
    my $graph = $graphs[$i];
    ### graph: "$graph"
    if (! blessed($graph)) {
      ### convert edge_aref ...
      $graph = edge_aref_to_Graph_Easy($graph);
    }
    my $graph6_filename = "/tmp/$i.g6";
    my $png_filename = "/tmp/$i.png";

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
    my $vertex_name_type;
    if ($graph->isa('Graph::Easy')) {
      $name = $graph->get_attribute('label');
      # FIXME: custom attributes?
      # $vertex_name_type = $graph->get_attribute('graph','vertex_name_type');
    } else {
      $name = $graph->get_graph_attribute('name');
      $vertex_name_type = $graph->get_graph_attribute('vertex_name_type');
    }
    $vertex_name_type //= '';
    $name //= '';
    my $canonical = graph6_str_to_canonical($graph6_str);
    if (length($canonical) > 30) {
      $canonical = '';
    } else {
      require HTML::Entities;
      $canonical = "<br> canonical "
        . HTML::Entities::encode_entities($canonical);
    }

    print $h <<"HERE";
<hr width="100%">
<p>
  <a href="file://$graph6_filename">$graph6_filename</a>
  $graph6_size bytes,
  $num_vertices vertices,
  $num_edges edges
  $name$canonical
HERE

    if ($num_vertices == 0) {
      print $h "empty\n";
      next;
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

    if ($num_vertices < 35) {
      if ($vertex_name_type =~ /^xy/) {
        my $graphviz2 = Graph_to_GraphViz2($graph);
        $graphviz2->run(format => 'png',
                        output_file=>$png_filename,
                        driver => 'neato');
      } else {
        my $easy = $graph;
        if ($graph->isa('Graph')) {
          ### Graph num nodes ...
          require Graph::Convert;
          $easy = Graph::Convert->as_graph_easy($graph);
        }
        # Graph_Easy_blank_labels($easy);
        foreach my $v (1,0) {
          if (defined($easy->node($v))) {
            $easy->set_attribute('root',$v);  # for as_graphviz()
            $easy->set_attribute('flow','south');  # for as_graphviz()
          }
        }
        ### Graph-Easy num nodes: scalar($easy->nodes)
        $easy->set_attribute('x-dot-start','1');
        my $graphviz = $easy->as_graphviz;
        # $graphviz =~ s/node \[/node [\n    height=.08,\n    width=.08,\n    fixedsize=1,/;
        # print $graphviz;

        require IPC::Run;
        IPC::Run::run(['dot','-Tpng'], '<',\$graphviz, '>',$png_filename);
        # IPC::Run::run(['neato','-Tpng'], '<',\$graphviz, '>',$png_filename);
        # IPC::Run::run(['fdp','-Tpng'], '<',\$graphviz, '>',$png_filename);
        # print $easy->as_ascii;
      }
      print $h qq{<img src="$png_filename">\n};
    }
  }

  print $h <<'HERE';
</body>
</html>
HERE
  close $h or die;

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

sub edge_aref_string {
  my ($edge_aref) = @_;
  return join(',', map{join('-',@$_)} @$edge_aref)
    . ' ['.scalar(@$edge_aref).' edges]';
}

#------------------------------------------------------------------------------
# nauty bits

sub graph6_view {
  my ($g6_str) = @_;
  Graph_view(Graph_from_graph6_str($g6_str));
}
sub graph6_str_to_canonical {
  my ($g6_str) = @_;
  ### graph6_str_to_canonical(): $g6_str

  # num_vertices == 0 is already canonical and nauty-labelg doesn't like to
  # crunch that
  if ($g6_str =~ /^\?/) {
    return $g6_str;
  }

  my $canonical;
  my $err;
  require IPC::Run;
  if (! IPC::Run::run(['nauty-labelg','-i2'],
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
  my ($graph) = @_;
  require Graph::Writer::Graph6;
  my $writer = Graph::Writer::Graph6->new;
  open my $fh, '>', \my $str or die;
  $writer->write_graph($graph, $fh);
  return $str;
}
sub Graph_from_graph6_str {
  my ($str) = @_;
  require Graph::Reader::Graph6;
  my $reader = Graph::Reader::Graph6->new;
  open my $fh, '<', \$str or die;
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

#------------------------------------------------------------------------------
# triangles

# ($a,$b,$c) are vertices of a triangle in $graph.
#      a
#     / \
#    b---c
# Return true if it is an even triangle.  For an even triangle every other
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

#------------------------------------------------------------------------------
# claws

# ($a,$b,$c,$d) = Graph_find_claw($graph);
# Return a list of vertices which are a claw (a 4-star) within $graph, as an
# induced subgraph.  $a is the centre.
#      b
#     /
#    a--c
#     \
#      d
sub Graph_find_claw {
  my ($graph) = @_;
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

          return ($a,$b,$c,$d);
        }
      }
    }
  }
  return;
}

# Return true if $graph contains a claw (star-4) as an induced subgraph.
sub Graph_has_claw {
  my ($graph) = @_;
  my @claw = Graph_find_claw($graph);
  ### found claw: @claw
  ### result: @claw > 0
  return @claw > 0;
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

# return true if all vertices of $graph have same degree
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
  my ($graph, $subgraph) = @_;
  my @graph_vertices    = sort $graph->vertices;
  my @subgraph_vertices = sort $subgraph->vertices;
  ### @graph_vertices
  ### @subgraph_vertices

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

      return join(', ',
                  map {"$subgraph_vertices[$_]=$graph_vertices[$map[$_]]"}
                  0 .. $#subgraph_vertices);
      return 1;
    }
    $map[$pos] = -1;
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
  my ($edge_aref, $subgraph_edge_aref,
      %option) = @_;
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

# $graph is a Graph.pm graph.
# Return true if $graph is a line graph, but checking none of Beineke G1 to
# G9 are induced subgraphs.
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
# GraphViz2 conversions

# file:///usr/share/doc/graphviz/html/info/attrs.html

sub Graph_to_GraphViz2 {
  my ($graph, %options) = @_;
  ### Graph_to_GraphViz2: %options
  require GraphViz2;
  $options{'vertex_name_type'}
    //= $graph->get_graph_attribute('vertex_name_type') // '';
  my $xy = ($options{'vertex_name_type'} =~ /^xy/);
  my $xy_triangular = ($options{'vertex_name_type'} =~ /^xy-triangular/);
  ### $xy

  my $name = $graph->get_graph_attribute('name');
  my $flow = ($options{'flow'} // 'down');
  my $graphviz2 = GraphViz2->new
    (directed => $graph->is_directed,
     graph  => { (defined $name ? (label   => $name) : ()),
                 (defined $flow ? (rankdir => $flow) : ()),
               },
     node => { margin => 0,  # cf default 0.11,0.055
             },
    );

  foreach my $v ($graph->vertices) {
    my @attrs;
    if ($xy) {
      my ($x,$y) = split /,/, $v;
      if ($xy_triangular) {
        $x *= 1/2;
        $y = sprintf '%.5f', $y*sqrt(3)/2;
      }
      push @attrs, pin=>1, pos=>"$x,$y";
      ### @attrs
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

sub GraphViz2_view {
  my ($graphviz2, %options) = @_;

  require File::Temp;
  my $ps = File::Temp->new (UNLINK => 0, SUFFIX => '.ps');
  my $ps_filename = $ps->filename;
  $graphviz2->run(format => 'ps', output_file=>$ps_filename,
                  ($options{'driver'} ? (driver => $options{'driver'}) : ()),
                  );
  postscript_view_file($ps_filename, %options);

  # $graphviz2->run(format => 'xlib',
  #                 driver => 'neato',
  #                );
}

#------------------------------------------------------------------------------

sub vertex_name_to_tikz {
  my ($name) = @_;
  $name =~ s/[,:]/-/g;
  return $name;
}

sub Graph_print_tikz {
  my ($graph) = @_;

  my @vertices = sort $graph->vertices;
  my $flow = 'east';
  my $rows = int(sqrt(scalar(@vertices)));
  my $r = 0;
  my $c = 0;
  foreach my $v (@vertices) {
    my $x = ($flow eq 'west' ? -$c : $c);
    my $vn = vertex_name_to_tikz($v);
    print "  \\node ($vn) at ($x,$r) [my box] {$v};\n";
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
    $to = vertex_name_to_tikz($to);
    if ($from eq $to) {
      print "  \\draw [$arrow,loop below] ($from) to $node();\n";
    } else {
      print "  \\draw [$arrow] ($from) to $node($to);\n";
    }
  }
  print "\n";
}


#------------------------------------------------------------------------------

# Return the clique number of Graph.pm $graph.
# The clique number is the number of vertices in the maximum clique
# (complete graph) contained.
# Brute force search here, much too slow for many vertices.
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


#------------------------------------------------------------------------------

sub Graph_is_hanging_cycle {
  my ($graph, $v) = @_;
  if ($graph->degree($v) != 2) { return 0; }
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

sub Graph_strip_hanging_cycles {
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

# $graph is a tree
# $v is a child node of $parent
# return the depth of the subtree $v and deeper underneath $parent
# if $v is a leaf then it is the entire subtree and the return is depth 1
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
# Hamiltonian

# by slow search
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

  foreach my $start ($type eq 'path' ? (@vertices) : ($vertices[0])) {
    my @path = ($start);
    my %visited = ($path[0] => 1);
    my @nn = (-1);
    my $upto = 0;
    for (;;) {
      ### at: join('--',@path)
      my $v = $path[$upto];
      my $n = $nn[$upto]++;
      my $to = $neighbours{$v}->[$n];
      ### $to
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
          return 1;
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

sub Graph_rename_vertex {
  my ($graph, $old_name, $new_name) = @_;
  ### $old_name
  ### $new_name

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

# return a new vertex name for $graph
sub Graph_new_vertex_name {
  my ($graph) = @_;
  my $upto = $graph->get_graph_attribute('Graph_new_vertex_name_upto') // 0;
  $upto++;
  $graph->set_graph_attribute('Graph_new_vertex_name_upto',$upto);
  return $upto;
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
# Replace each vertex by an N-star (star of $N vertices).
# Existing edges become edges between an arm of the new stars.
#
# edges_between => $integer, default 1
#     Number of edges in connections between new stars.
#     Default 1 is replacing each edge by an edge between the stars.
#     > 1 means extra vertices for those connections.
#     0 means the stars have a vertex in common for existing edges.
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

# return a list of vertices which are a path achieving the eccentricity of $v
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

sub Graph_leaf_vertices {
  my ($graph) = @_;
  return grep {$graph->vertex_degree($_)<=1} $graph->vertices;
}

# return a list of vertices which attain the diameter of tree $graph
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

#------------------------------------------------------------------------------
1;
__END__
