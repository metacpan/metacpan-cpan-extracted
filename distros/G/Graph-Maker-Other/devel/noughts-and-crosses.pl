#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde
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
use List::Util 'sum';
use Graph::Maker::NoughtsAndCrosses;

use FindBin;
use lib "$FindBin::Bin/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;



{
  # HOG
  # N=2 all
  #   1-player  https://hog.grinvin.org/ViewGraphInfo.action?id=27032
  #             tesseract induced subgraph
  #             binaries up to two 1-bits
  #   2-player  https://hog.grinvin.org/ViewGraphInfo.action?id=27017
  #   3-player  hog not, 64 edges
  #   4-player  hog not, tree 64 edges
  #
  # N=2 up to reflection
  #   1-player  https://hog.grinvin.org/ViewGraphInfo.action?id=856
  #   2-player  hog not, outer ring 12, inside 1+2
  #   3-player  hog not, outer ring many, inside 1+2
  #   4-player  hog not, tree complete 2,3,2,1
  #
  # N=2 up to rotation
  #   1-player  claw
  #             sans root  2-path
  #   2-player  cross links, 6 cycle and middle
  #             https://hog.grinvin.org/ViewGraphInfo.action?id=27020
  #             sans root  broken wheel 7 spokes 1,3,5
  #             https://hog.grinvin.org/ViewGraphInfo.action?id=27022
  #   3-player  12-cycle and middle
  #             https://hog.grinvin.org/ViewGraphInfo.action?id=27025
  #             sans root  12-cycle and middle, broken wheel 7
  #             https://hog.grinvin.org/ViewGraphInfo.action?id=27027
  #   4-player  tree 1,3,2,1
  #             https://hog.grinvin.org/ViewGraphInfo.action?id=27034
  #             or sans root  tree 3,2,1
  #
  # N=2 up to rot+ref
  #   1-player  claw
  #   2-player  "A"-graph
  #             https://hog.grinvin.org/ViewGraphInfo.action?id=945
  #   3-player  5-cycle with 2 hanging
  #             https://hog.grinvin.org/ViewGraphInfo.action?id=27048
  #   4-player  small tree
  #             https://hog.grinvin.org/ViewGraphInfo.action?id=27050
  #
  # N=3 up to rot+ref
  #   1-player  87 vertices
  #             https://hog.grinvin.org/ViewGraphInfo.action?id=27015
  #   2-player  765 vertices too big
  #
  my @graphs;
  foreach my $N (1 .. 4) {
    my $graph = Graph::Maker->new
      ('noughts_and_crosses',
       N       => 2,
       players => $N,
       rotate  => 1,
       reflect => 1,
       # undirected => 1,
      );
    last if $graph->vertices > 255;
    # $graph->delete_vertex('0000');   # sans root
    # Graph_print_tikz($graph);
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}

{
  # view
  foreach my $N (2) {
    my $graph = Graph::Maker->new
      ('noughts_and_crosses',
       N => $N,
       players => 1,
       rotate => 0,
       reflect => 0,
      );
    my $name = $graph->get_graph_attribute ('name');
    print "$name\n";
     Graph_print_tikz($graph);
    my $num_vertices = $graph->vertices;
    my $num_edges    = $graph->edges;
    my $diameter = $graph->diameter || 0;
    print "  vertices $num_vertices edges $num_edges diameter $diameter\n";
    Graph_view($graph);
  }
  exit 0;
}
{
  # num vertices, num edges

  foreach my $players (-1, 1,2,3,4) {
    foreach my $rotate (1,0) {
      foreach my $reflect (1,0) {
        my @vertices;
        my @edges;
        foreach my $N (2 .. 3) {
          my $graph = Graph::Maker->new
            ('noughts_and_crosses',
             N => $N,
             players => ($players==-1 ? $N**2 : $players),
             rotate => $rotate,
             reflect => $reflect,
             # graph_maker => sub { return MyGraphs::Graph::CountEdges->new(@_); },
             graph_maker => sub { return MyGraphs::Graph::CountCheck->new(@_); },
            );
          my $name = $graph->get_graph_attribute ('name');
          print "$name\n";
          my $num_vertices = $graph->vertices;
          my $num_edges    = $graph->edges;
          push @vertices, $num_vertices;
          push @edges, $num_edges;
          last if $num_edges > 1000;
        }
        require Math::OEIS::Grep;
        Math::OEIS::Grep->search(array => \@vertices,
                                 verbose=>1,
                                 name => "vertices players=$players rotate=$rotate reflect=$reflect");
        Math::OEIS::Grep->search(array => \@edges,
                                 verbose=>1,
                                 name => "edges players=$players rotate=$rotate reflect=$reflect");
      }
    }
  }
  exit 0;
}

{
  # 3x3, 1 player, up to rot+ref,  47 vertices

  my $graph = Graph::Maker->new
    ('noughts_and_crosses',
     N => 3,
     players => 1,
     rotate => 1,
     reflect => 1,
     undirected => 1,
    );

  # $graph = $graph->undirected_copy;
  print "degree sequence: ",join(',',MyGraphs::Graph_degree_sequence($graph)),"\n";

  foreach my $v (sort $graph->vertices) {
    if ($graph->vertex_degree($v) == 3) {
      my $degree = $graph->vertex_degree($v);
    my $ecc = $graph->vertex_eccentricity($v);
      my @neighbours = $graph->neighbours($v);
      my @neighbour_degrees = map {$graph->vertex_degree($_)} @neighbours;
      @neighbour_degrees = sort {$a<=>$b} @neighbour_degrees;
      print "$v degree $degree ecc $ecc neighbours ",join(',',@neighbour_degrees),"\n";
    }
  }
  exit 0;
}


{
  # N^2 players
  #
  # not in OEIS: ???    vertices
  # not in OEIS: 1,64,986409    edges
  # first player N^2 choices
  # second player N^2-1 choices for each of them
  # count(n) = my(total=0,width=1); for(i=0,n^2, total += width; width*=(n^2-i)); total;
  # vector(6,n, count(n))
  # 1 + 9 + 9*8 + 9*8*7 + 9*8*7*6 + 9*8*7*6*5 + 9*8*7*6*5*4 + 9*8*7*6*5*4*3 + 9*8*7*6*5*4*3*2 + 9*8*7*6*5*4*3*2*1
  # 
  #
  # up to rotate and reflect
  # not in OEIS: 1,7,77950    edges
  # vertices 2,10,123310 = A085698

  foreach my $N (0..3) {
    my $graph = Graph::Maker->new
      ('noughts_and_crosses',
       N => $N, players => $N**2,
       # rotate => 1,
       # reflect => 1,
       graph_maker => sub { return MyGraphs::Graph::CountEdges->new(@_); },
       # graph_maker => sub { return MyGraphs::Graph::CountCheck->new(@_); },
      );
    my $name = $graph->get_graph_attribute ('name');
    print "$name\n";
    my $num_vertices = $graph->vertices;
    my $num_edges    = $graph->edges;
    my $diameter = 0; # $graph->diameter || 0;
    print "  vertices $num_vertices edges $num_edges diameter $diameter\n";

    # $graph = Graph::Maker->new
    #   ('noughts_and_crosses',
    #    N => $N, players => $N**2,
    #    # rotate => 1,
    #    # reflect => 1,
    #   );
    # Graph_view($graph);
  }
  exit 0;
}

{
  # 2 player rot+ref
  #   vertices 0,2,6,765
  #   edges 0,1,6,2096
  #   4x4 >= 1.5m edges maybe
  # 1 player rot+ref
  #   vertices 0,2,4,87,8043
  #   edges 0,1,2,46,4961
  # 3 player rot+ref
  #   vertices 0,2,9,3495
  #   edges    0,1,7,3152

  foreach my $N (0,1,2,3,4) {
    my $graph = Graph::Maker->new
      ('noughts_and_crosses',
       N => $N,
       players => 3,
       rotate => 1,
       reflect => 1,
       # graph_maker => sub { return MyGraphs::Graph::CountEdges->new(@_); },
       graph_maker => sub { return MyGraphs::Graph::CountCheck->new(@_); },
      );
    my $name = $graph->get_graph_attribute ('name');
    print "$name\n";
    my $num_vertices = $graph->vertices;
    my $num_edges    = $graph->edges;
    my $diameter = 0; # $graph->diameter || 0;
    print "  vertices $num_vertices edges $num_edges diameter $diameter\n";
  }
  exit 0;
}
{
  # 2x2 3-player rot+ref
  foreach my $N (3) {
    my $graph = Graph::Maker->new
      ('noughts_and_crosses',
       N => $N,
       players => 1,
       rotate => 1,
       reflect => 1,
       # graph_maker => sub { return MyGraphs::Graph::CountEdges->new(@_); },
       # graph_maker => sub { return MyGraphs::Graph::CountCheck->new(@_); },
      );
    Graph_view($graph);
  }
  exit 0;
}
{
  # noughts and crosses 3x3
  # 0 1 2
  # 3 4 5
  # 6 7 8

  # 1 players is 87 states up to rotation+reflection
  # 2 players is 765 states up to rotation+reflection
  #

  my $num_players = 1;

  my @lines = ([0,1,2],[3,4,5],[6,7,8],
               [0,3,6],[1,4,7],[2,5,8],
               [0,4,8],[2,4,6]);
  my $is_winning = sub {
    my ($state) = @_;
    foreach my $line (@lines) {
      my @count = (0,0,0);
      foreach my $pos (@$line) {
        $count[substr($state,$pos,1)]++;
      }
      foreach my $side (1,2) {
        if ($count[$side]==3) { return $side; }
      }
    }
    return 0;
  };
  my $rotate_plus90 = sub {
    my ($state) = @_;
    join('',map {substr($state,$_,1)} 2,5,8, 1,4,7, 0,3,6);
  };
  my $mirror_horizontal = sub {
    my ($state) = @_;
    join('',map {substr($state,$_,1)} 2,1,0, 5,4,3, 8,7,6);
  };
  my $all_symmetries = sub {
    my ($state) = @_;
    {
      # rotation and reflection
      my @rot = ($state, $rotate_plus90->($state));
      push @rot, $rotate_plus90->($rot[-1]);
      push @rot, $rotate_plus90->($rot[-1]);
      return sort map {$_,$mirror_horizontal->($_)} @rot;
    }
  };
  my %canonical;
  my $state_to_canonical = sub {
    my ($state) = @_;
    if (exists $canonical{$state}) {
      return $canonical{$state};
    }
    my @sym_states = $all_symmetries->($state);
    @sym_states = sort @sym_states;
    foreach my $sym_state (@sym_states) {
      $canonical{$sym_state} = $sym_states[0];
    }
    return $sym_states[0];
  };
  my @pending = ('000000000');
  my %seen;
  my $count_winning = 0;
  my $side = 1;
  my $count_unsymmetric = 0;
  require Graph;
  my $graph = Graph->new (undirected => 0);
  while (@pending) {
    print "pending ",scalar(@pending),"\n";
    my @new_pending;
    foreach my $state (@pending) {
      $graph->add_vertex($state);
      if ($is_winning->($state)) {
        $count_winning++;
        next;
      }
      foreach my $pos (0 .. length($state)-1) {
        next if substr($state,$pos,1);
        my $new_state = $state;
        substr($new_state,$pos,1, $side);
        $new_state = $state_to_canonical->($new_state);
        $graph->add_edge($state,$new_state);
        unless ($seen{$new_state}++) {
          push @new_pending, $new_state;
          $count_unsymmetric++;
        }
      }
    }
    @pending = @new_pending;

    $side++;
    if ($side > $num_players) { $side = 1; }
  }
  my $count_states = scalar(keys %seen);
  print "total states $count_states, winning $count_winning\n";
  print "up to symmetry $count_unsymmetric\n";
  print "vertices ",scalar($graph->vertices),"\n";
  print "edges ",scalar($graph->edges),"\n";
  Graph_view($graph);

  print "6-piece non-winning states\n";
  foreach my $v (sort $graph->vertices) {
    my $count = sum(split //,$v);
    next unless $count == 6;
    next if $is_winning->($v);
    my $degree = $graph->vertex_degree($v);
    print "$v degree $degree\n";
  }

  $graph = $graph->undirected_copy;
  print "degree sequence: ",join(',',MyGraphs::Graph_degree_sequence($graph)),"\n";

  foreach my $v (sort $graph->vertices) {
    my $degree = $graph->vertex_degree($v);
    my $ecc = $graph->vertex_eccentricity($v);
    my @neighbours = $graph->neighbours($v);
    my @neighbour_degrees = map {$graph->vertex_degree($_)} @neighbours;
    @neighbour_degrees = sort {$a<=>$b} @neighbour_degrees;
    print "$v ecc $ecc degree $degree neighbours ",join(',',@neighbour_degrees),"\n";
  }
  
  print "7-piece states\n";
  foreach my $v (sort $graph->vertices) {
    my $count = sum(split //,$v);
    next unless $count == 7;
    my $degree = $graph->vertex_degree($v);
    print "$v degree $degree\n";
  }
  exit 0;
}

{
  # noughts and crosses 2x2
  # 0 1
  # 2 3
  my @lines = ([0,1],[2,3],
               [0,2],[1,3],
               [0,3],[1,2]);
  my $is_winning = sub {
    my ($state) = @_;
    foreach my $line (@lines) {
      my @count = (0,0,0);
      foreach my $pos (@$line) {
        $count[substr($state,$pos,1)]++;
      }
      foreach my $side (1,2) {
        if ($count[$side]==2) { return $side; }
      }
    }
    return 0;
  };
  my $rotate_plus90 = sub {
    my ($state) = @_;
    join('',map {substr($state,$_,1)} 1,3, 0,2);
  };
  my $mirror_horizontal = sub {
    my ($state) = @_;
    join('',map {substr($state,$_,1)} 1,0, 3,2);
  };
  my $all_symmetries = sub {
    my ($state) = @_;
    {
      # rotation
      my @rot = ($state, $rotate_plus90->($state));
      push @rot, $rotate_plus90->($rot[-1]);
      push @rot, $rotate_plus90->($rot[-1]);
      return sort @rot;
    }
    {
      # fixed orientation
      return $state;
    }
    {
      # rotation and reflection
      my @rot = ($state, $rotate_plus90->($state));
      push @rot, $rotate_plus90->($rot[-1]);
      push @rot, $rotate_plus90->($rot[-1]);
      return sort map {$_,$mirror_horizontal->($_)} @rot;
    }
  };
  my %canonical;
  my $state_to_canonical = sub {
    my ($state) = @_;
    if (exists $canonical{$state}) {
      return $canonical{$state};
    }
    my @sym_states = $all_symmetries->($state);
    @sym_states = sort @sym_states;
    foreach my $sym_state (@sym_states) {
      $canonical{$sym_state} = $sym_states[0];
    }
    return $sym_states[0];
  };
  my $state_to_vertex = sub {
    my ($state) = @_;
    substr($state,2,0, "-");
    return $state;
  };
  my @pending = ('0000');
  my %seen;
  my $count_winning = 0;
  my $side = 1;
  my $count_unsymmetric = 0;
  require Graph;
  my $graph = Graph->new;
  while (@pending) {
    print "pending ",scalar(@pending),"\n";
    my @new_pending;
    foreach my $state (@pending) {
      $graph->add_vertex($state_to_vertex->($state));
      if ($is_winning->($state)) {
        $count_winning++;
        next;
      }
      foreach my $pos (0 .. length($state)-1) {
        next if substr($state,$pos,1);
        my $new_state = $state;
        substr($new_state,$pos,1, $side);
        $new_state = $state_to_canonical->($new_state);
        $graph->add_edge($state_to_vertex->($state),
                         $state_to_vertex->($new_state));
        unless ($seen{$new_state}++) {
          push @new_pending, $new_state;
          $count_unsymmetric++;
        }
      }
    }
    @pending = @new_pending;
    $side = 3-$side;
  }
  my $count_states = scalar(keys %seen);
  print "total states $count_states, winning $count_winning\n";
  print "up to symmetry $count_unsymmetric\n";
  print "vertices ",scalar($graph->vertices),"\n";
  print "edges ",scalar($graph->edges),"\n";
  Graph_view($graph);
  Graph_print_tikz($graph);
  hog_searches_html($graph);
  exit 0;
}


{
  # A subclass of Graph.pm which doesn't add any vertices or edges but just
  # counts edges.

  package MyGraphs::Graph::CountEdges;
  our @ISA;
  BEGIN { @ISA = ('Graph'); }
  sub new {
    my $class = shift;
    return bless {num_edges => 0,
                  @_}, $class; 

    require Graph;
    my $self = $class->SUPER::new (@_);
    $self->{'num_edges'}    = 0;
    return $self;
  }
  sub add_vertex {
    my ($self) = @_;
  }
  sub add_edge {
    my ($self) = @_;
    $self->{'num_edges'}++;
    if (main::progress()) {
      print $self->{'num_edges'},"\r";
    }
  }
  sub vertices {
    my ($self) = @_;
    return 0;
  }
  sub edges {
    my ($self) = @_;
    return $self->{'num_edges'};
  }
  sub set_graph_attribute {
    my ($self, $name, $value) = @_;
    $self->{'attributes'}->{$name} = $value;
  }
  sub get_graph_attribute {
    my ($self, $name) = @_;
    return $self->{'attributes'}->{$name};
  }
  sub is_directed {
    my ($self, $name) = @_;
    return 0;
  }
}
{
  package MyGraphs::Graph::CountCheck;
  use Carp 'croak';
  sub new {
    my $class = shift;
    return bless {vertices => {},
                  edges => {},
                  @_}, $class; 
  }
  sub add_vertex {
    my ($self, $v) = @_;
    $self->{'vertices'}->{$v} = 1;
    if (main::progress()) {
      print scalar(keys %{$self->{'vertices'}}),"\r";
    }
  }
  sub add_edge {
    my ($self, $u, $v) = @_;
    $self->add_vertex($u);
    $self->add_vertex($v);
    if ($self->{'edges'}->{$u,$v}++) {
      croak "duplicate edge $u to $v";
    }
  }
  sub vertices {
    my ($self) = @_;
    return keys %{$self->{vertices}};
  }
  sub edges {
    my ($self) = @_;
    return keys %{$self->{edges}};
  }
  sub set_graph_attribute {
    my ($self, $name, $value) = @_;
    $self->{'attributes'}->{$name} = $value;
  }
  sub get_graph_attribute {
    my ($self, $name) = @_;
    return $self->{'attributes'}->{$name};
  }
  sub is_directed {
    my ($self, $name) = @_;
    return 0;
  }
}
{
  my $t;
  sub progress {
    my $old_t = $t || time();
    $t = time();
    return ($t != $old_t);
  }
}






    # my @pending = ('0' x ($N*$N));
    # $graph->add_vertex($state_to_str->($pending[0]));
    # while (@pending) {
    #   ### pending: scalar(@pending)
    #   my @new_pending;
    #   foreach my $state (@pending) {
    #     ### $state
    #     my %seen_to;
    #     foreach my $pos (0 .. length($state)-1) {
    #       next if substr($state,$pos,1);
    #       my $new_state = $state;
    #       substr($new_state,$pos,1, $player);
    #       $new_state = $state_to_canonical->($new_state);
    #
    #       unless ($seen_to{$new_state}++) {
    #         $graph->add_edge($state_to_str->($state),
    #                          $state_to_str->($new_state));
    #       }
    #       unless ($seen{$new_state}++
    #               || $state_is_winning->($new_state)) {
    #         #### to: $new_state
    #         push @new_pending, $new_state;
    #         $seen{$new_state} = $new_state;
    #       }
    #     }
    #   }
    #   @pending = @new_pending;
    #
    #   $player++;
    #   if ($player > $players) { $player = 1; }
    # }

