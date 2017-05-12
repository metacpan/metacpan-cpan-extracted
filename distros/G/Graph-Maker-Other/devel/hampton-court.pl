#!/usr/bin/perl -w

# Copyright 2015, 2016 Kevin Ryde
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

use strict;
use Graph;
use MyGraphs;

{
  # Hampton Court
  # https://hog.grinvin.org/ViewGraphInfo.action?id=21084
  # straight-line diagram in W.H.Matthews fig 136

  require Graph::Easy;
  require Graph::Easy::As_graph6;
  # file:///usr/share/doc/graphviz/html/info/lang.html

  my $str = <<'HERE';
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
X            X     X          X               X
X XXXXXXXXXX X XXXXX @@@@@@@@ X XXXXXXXXXXXXX X
X X          X X            @ X             X X
X X XXXXXXXXXX X XXXXXXXXXX @ XXXXXXXXXXXXX X X
X X X          X    X       @             X X X
X X X XXXXXXXXXXXXX X @@@@@@@@@@@@@ XXXXX X X X
X X X X   X         X             @ X   X X X X
X X   X X X XXXXXXXXXXXXXXXXXXXXX @ X X X X X X
X XXX X X X X...................X @ X X X   X X
X   X X X X X...................X @ X X X XXX X
XXX X X X X X.......G...........X @ X X X X   X
X   X X X X X....... ...........X @ X X X X XXX
X XXX X X X X....... ...........X @ X X X X   X
X X   X X X XXXXXXXX XXXXXXXXXXXX @ X X X X X X
X X X X X X        X X            @ X X   X X X
X X X X X XXXXXXXX X X @@@@@@@@@@@@ X XXXXX X X
X X X   X        X X X                X     X X
X X XXXXXXXXXXXXXX X XXXXXXXXXXXXXXXXXXXXXXXX X
X X                X                          X
X XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
X                                             X
XXXXXXXXXXXXXXXXXXXXEXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
HERE
  $str =~ s/\n$//;
  my @rows = split /\n/, $str;
  my $width = length($rows[0]);
  my $xy_to_name = sub {
    my ($x,$y) = @_;
    return "p$x,$y";
  };
  my $get = sub {
    my ($x,$y) = @_;
    return substr($rows[$y],$x,1);
  };
  my @dir4_to_dx = (1,0,-1,0);
  my @dir4_to_dy = (0,1,0,-1);

  my $easy = Graph::Easy->new (undirected => 1);
  my ($ex,$ey);
  my ($gx,$gy);
  foreach my $y (0 .. $#rows) {
    foreach my $x (0 .. $width) {
      my $c = $get->($x,$y);
      print $c;
      if ($c eq ' ') {
        $easy->add_vertex($xy_to_name->($x,$y));
        foreach my $dir (0 .. $#dir4_to_dx) {
          my $x2 = $x + $dir4_to_dx[$dir];
          my $y2 = $y + $dir4_to_dy[$dir];
          my $c2 = $get->($x2,$y2);
          next unless $c2 eq ' ';
          $easy->add_edge_once( sort($xy_to_name->($x,$y),
                                     $xy_to_name->($x2,$y2)));
        }
      } elsif ($c eq 'E') {
        ($ex,$ey) = ($x,$y-1);
      } elsif ($c eq 'G') {
        ($gx,$gy) = ($x,$y+1);
      }
    }
    print "\n";
  }

  my $entrance_name = 'Entrance';
  $easy->set_attribute('flow','east');
  $easy->rename_node($easy->node($xy_to_name->($ex,$ey)), $entrance_name);
  $easy->set_attribute('root',$entrance_name); # for as_graphviz()
  $easy->{att}->{root} = $entrance_name;       # for root_node() for as_ascii()
  $easy->node($entrance_name)->set_attribute('x-dot-pos',"0,0!");
  $easy->set_attribute('x-dot-overlap',"false");
  $easy->set_attribute('x-dot-splines',"true");

  $easy->rename_node($easy->node($xy_to_name->($gx,$gy)),"Goal");
  $easy->node("Goal")->set_attribute('x-dot-pos',"8,0!");

  Graph_Easy_branch_reduce($easy);

  my @entrance_edges = $easy->node($entrance_name)->edges;
  my $entrance_degree = scalar(@entrance_edges);
  print "entrance degree $entrance_degree   ",
    Graph_Easy_edge_list_string(@entrance_edges),"\n";

  my $num_nodes = $easy->nodes;
  print "$num_nodes nodes\n";
  print $easy->as_graphviz;
  print $easy->as_graph6;
  print graph6_str_to_canonical($easy->as_graph6);
  Graph_Easy_view($easy);
  hog_searches_html($easy);
  exit 0;

  sub Graph_Easy_branch_reduce {
    my ($easy) = @_;
    my $root = $easy->attribute('root');
    ### $root
    my $more;
    do {
      $more = 0;
      foreach my $v ($easy->vertices) {
        my @edges = $v->edges;
        if ($v->name ne $root && @edges == 2) {
          ### del: "$v"
          my @join = grep {$_ != $v} ($edges[0]->from,
                                      $edges[0]->to,
                                      $edges[1]->from,
                                      $edges[1]->to);
          $easy->del_edge($edges[0]);
          $easy->del_edge($edges[1]);
          $easy->del_node($v);
          $easy->add_edge(@join);
          $more = 1;
        }
      }
    } while ($more);
  }
}

