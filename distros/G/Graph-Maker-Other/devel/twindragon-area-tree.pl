#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018, 2019 Kevin Ryde
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
use List::Util 'min','max','sum';
use Graph::Maker::TwindragonAreaTree;

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;
$| = 1;

# uncomment this to run the ### lines
# use Smart::Comments;




{
  # House of Graphs
  #  k=0 https://hog.grinvin.org/ViewGraphInfo.action?id=1310    single vertex
  #  k=1 https://hog.grinvin.org/ViewGraphInfo.action?id=19655   path-2
  #  k=2 https://hog.grinvin.org/ViewGraphInfo.action?id=594     path-4
  #  k=3 https://hog.grinvin.org/ViewGraphInfo.action?id=700
  #  k=4 https://hog.grinvin.org/ViewGraphInfo.action?id=28549
  #  k=5 https://hog.grinvin.org/ViewGraphInfo.action?id=31086
  my @graphs;
  foreach my $k (0 .. 8) {
    my $graph = Graph::Maker->new('twindragon_area_tree', level=>$k,
                                  undirected=>1);
    # MyGraphs::Graph_branch_reduce($graph);
    # if($k==3) { MyGraphs::Graph_view($graph); }
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}
{
  # sample picture for POD

  my $level = 6;
  my $scale_y = 2;
  my $scale_x = 4;

  require Image::Base::Text;
  my $image = Image::Base::Text->new (-width => 80, -height => 40);
  my $offset_x = 50;
  my $offset_y = 20;

  my $draw_text = sub {
    my ($x,$y, $str) = @_;
    $y = -$y;
    $x *= $scale_x;
    $y *= $scale_y;
    $x += $offset_x;
    $y += $offset_y;
    $x -= length($str)-1;
    foreach my $i (0 .. length($str)-1) {
      $image->xy($x+$i,$y, substr($str,$i,1));
    }
  };
  my $draw_line = sub {
    my ($x,$y, $x2,$y2) = @_;
    $y = -$y;
    $y2 = -$y2;
    my $dx = $x2-$x; if ($dx) { $dx /= abs($dx); }
    my $dy = $y2-$y; if ($dy) { $dy /= abs($dy); }
    my $char = $dx ? '-' : '|';
    $x *= $scale_x;
    $y *= $scale_y;
    $x += $offset_x;
    $y += $offset_y;
    $x2 *= $scale_x;
    $y2 *= $scale_y;
    $x2 += $offset_x;
    $y2 += $offset_y;
    ### line: "$x,$y to $x2,$y2  by $dx,$dy"
    while ($x != $x2 || $y != $y2) {
      ### at: "$x,$y"
      if ($image->xy($x,$y) eq ' ') {
        $image->xy($x,$y, $char);
      }
      $x += $dx;
      $y += $dy;
    }
  };

  require Math::PlanePath::ComplexPlus;
  my $path = Math::PlanePath::ComplexPlus->new;
  my $graph = Graph::Maker->new ('twindragon_area_tree', level => $level);
  foreach my $n ($graph->vertices) {
    my ($x,$y) = $path->n_to_xy($n);
    $draw_text->($x,$y, $n);
  }
  foreach my $edge ($graph->edges) {
    my ($v1,$v2) = @$edge;
    my ($x1,$y1) = $path->n_to_xy($v1);
    my ($x2,$y2) = $path->n_to_xy($v2);
    $draw_line->($x1,$y1, $x2,$y2);
  }

  $image->save('/dev/stdout');
  exit 0;
}

{
  # trees symmetric and symmetric halves all the way down
  #
  # same vertex in each
  # (1,) 1,2,8,64,1024    = 2^(n(n-1)/2)
  # not 65536=2^16=64*2^10, only 1024=2^10 unique
  # same vertex, leaf = path only
  #
  # same vertex, degree <=2
  # not in OEIS: 1,2,7,36,587,14834
  #
  # same eccentricity
  # not in OEIS: 1,   1,2,9,122,5894,
  # same eccentricity, degree <=2
  # not in OEIS: 1,2,8, 80,2210,
  #

  my $connect_max_degree = 0;
  my $connect_at_same = 0;

  require Graph::Graph6;
  require IPC::Run;
  Graph::Graph6::write_graph(filename  => '/tmp/1.s6',
                                 edge_aref => [ [0,1] ],
                                 format    => 'sparse6',
                                );
  foreach my $i (1 .. 10) {
    # if ($i == 4) {
    #   my @graphs;
    #   open my $fh, '<', "/tmp/$i.s6" or die;
    #   require Graph::Reader::Graph6;
      #   my $reader = Graph::Reader::Graph6->new;
    #   while (my $graph = $reader->read_graph($fh)) {
    #     push @graphs, $graph;
    #   }
    #   hog_searches_html(@graphs);
    #   exit;
    # }

    my $num_vertices;
    my @edges;
    open my $fh, '<', "/tmp/$i.s6" or die;
    open my $out, '>', "/tmp/new.s6" or die;
    my $count = 0;
    while (Graph::Graph6::read_graph(fh               => $fh,
                                     num_vertices_ref => \$num_vertices,
                                     edge_aref        => \@edges,
                                    )) {
      $count++;
      print "$count\r";

      my @eccentricity = map {MyGraphs::edge_aref_eccentricity(\@edges,$_)}
        0 .. scalar(@edges);
      ### @eccentricity

      # two copies, with $new_edges[0] dummy to be changed
      my @new_edges = ([-1,-1],
                       @edges,
                       map {[ $_->[0]+$num_vertices, $_->[1]+$num_vertices ]}
                       @edges);

      foreach my $v (0 .. $num_vertices-1) {
        $new_edges[0]->[0] = $v;
        next if ($connect_max_degree
                 && edge_aref_vertex_degree(\@edges, $v) > $connect_max_degree);

        foreach my $v2 ($connect_at_same ? ($v) : (0 .. $num_vertices-1)) {
        next if ($connect_max_degree
                 && edge_aref_vertex_degree(\@edges, $v2) > $connect_max_degree);

          if ($eccentricity[$v] == $eccentricity[$v2]) {
            $new_edges[0]->[1] = $v2 + $num_vertices;
            Graph::Graph6::write_graph(fh        => $out,
                                       edge_aref => \@new_edges,
                                       format    => 'sparse6',
                                      );
          }
        }
      }
    }
    print "k=$i  v=$num_vertices  uniq $count\n";

    IPC::Run::run(['nauty-labelg'],
                  '<', '/tmp/new.s6',
                  '|', ['sort','-u'],
                  '|', ['tee', '/tmp/'.($i+1).'.s6'],
                  '|', ['wc','-l']);
  }
  exit 0;

  sub edge_aref_vertex_is_leaf {
    my ($edge_aref, $v) = @_;
    my $count = 0;
    foreach my $edge (@$edge_aref) {
      $count += ($edge->[0] == $v);
      $count += ($edge->[1] == $v);
      if ($count > 1) { return 0; }
    }
    return 1;
  }
  sub edge_aref_vertex_degree {
    my ($edge_aref, $v) = @_;
    return scalar((  grep {$_->[0] == $v} @$edge_aref)
                  + (grep {$_->[1] == $v} @$edge_aref));
  }
}
{
  # vertices away from PlusOffsetVH vertex
  # eccentricity = JA
  # vector(16,k,JA(k))
  # three join area trees  JA k, k+1, k+2
  my @values;
  foreach my $k (1 .. 14) {
    my $graph = Graph::Maker->new('twindragon_area_tree', level=>$k,
                                  undirected=>1);
    my $v = int(2**$k/3);
    my @widths = Graph_width_list($graph,$v);
    my @neighbours = $graph->neighbours($v);
    @neighbours = sort {$a<=>$b} @neighbours;

    $graph->delete_vertex($v);

    my @components = $graph->connected_components;
    @components = map {scalar(@$_)} @components;
    @components = sort {$a<=>$b} @components;
    my $total = sum(@components);
    printf "k=%d v=%d [%b] %s [%b]   = %d\n",
      $k, $v,$v, join(',',@components), $components[-1], $total;

    my @eccentricities
      = map {Graph_eccentricity_in_component($graph,$_)} @neighbours;
    @eccentricities = sort {$a<=>$b} @eccentricities;
    printf "  eccentricities %s  [%b]\n",
      join(',',@eccentricities), $eccentricities[-1];

    if ($#widths > 30) { $#widths = 30; }
    print "  ",join(',',@widths),"\n";

    # push @values, $components[0];
    push @values, $eccentricities[0];
  }
  require Math::OEIS::Grep;
  Math::OEIS::Grep->search(array => \@values, verbose=>1);
  exit 0;

  sub Graph_eccentricity_in_component {
    my ($graph, $v) = @_;
    my %seen = ($v => 1);
    my @pending = ($v);
    my $ecc = 0;
    while (@pending) {
      $ecc++;
      my @new_pending;
      foreach my $v (@pending) {
        foreach my $t ($graph->neighbours($v)) {
          if (! $seen{$t}) {
            $seen{$t}=1;
            push @new_pending, $t;
          }
        }
      }
      @pending = @new_pending;
    }
    return $ecc;
  }
}



{
  # degrees
  foreach my $k (5) {
    my $graph = Graph::Maker->new('twindragon_area_tree', level=>$k,
                                  undirected=>1);

    require Graph::Writer::Sparse6;
    my $writer = Graph::Writer::Sparse6->new (header => 1);
    my $sparse6_str;
    open my $fh, '>', \$sparse6_str;
    $writer->write_graph($graph, $fh);
    print $sparse6_str;
    my $canon_str = graph6_str_to_canonical($sparse6_str);
    print $canon_str;

    foreach my $v (0 .. 2**$k-1) {
      my @neighbours = $graph->neighbours($v);
      @neighbours = grep {$_ < $v} @neighbours;
      print scalar(@neighbours)," ";
      # last if $v > 120;
    }
    print "\n";
  }
  exit 0;
}


{
  # POD sample code

  use Math::PlanePath::ComplexPlus;
  my $path = Math::PlanePath::ComplexPlus->new;
  my $graph = Graph::Maker->new ('twindragon_area_tree', level=>5);
  foreach my $edge ($graph->edges) {
    my ($v1,$v2) = @$edge;
    my ($x1,$y1) = $path->n_to_xy($v1);
    my ($x2,$y2) = $path->n_to_xy($v2);
    print "draw an edge from ($x1,$y1) to ($x2,$y2) ...\n";

    abs($x1-$x2) <= 1 or die;
    abs($y1-$y2) <= 1 or die;
  }
  exit 0;
}

{
  # compared to TwindragonAreaTreeByPath

  require Graph::Maker::TwindragonAreaTreeByPath;
  foreach my $k (0 .. 10) {
    my $graph = Graph::Maker->new('twindragon_area_tree', level=>$k,
                                  undirected=>1);
    my $gpath = Graph::Maker->new('twindragon_area_tree_by_path', level=>$k,
                                  undirected=>1);

    # print "$gpath\n";
    # foreach my $edge (sort {max(@$a) <=> max(@$b)
    #                           || min(@$a) <=> min(@$b)
    #                         } $gpath->edges) {
    #   my ($v1, $v2) = @$edge;
    #   if ($v1 > $v2) { ($v1,$v2) = ($v2,$v1); }
    #   printf "  %*b %*b\n", $k, $v1, $k, $v2;
    # }
    # foreach my $edge (sort {max(@$a) <=> max(@$b)
    #                           || min(@$a) <=> min(@$b)
    #                         } $graph->edges) {
    #   my ($v1, $v2) = @$edge;
    #   if ($v1 > $v2) { ($v1,$v2) = ($v2,$v1); }
    #   printf "  %*b %*b\n", $k, $v1, $k, $v2;
    # }

    my $bool = Graph_is_isomorphic($graph, $gpath);
    print "k=$k  ",$bool ? "yes" : "no", "\n";
  }
  exit 0;
}

