#!/usr/bin/perl -w

# Copyright 2018 Kevin Ryde
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
use 5.010;
use List::Util 'min','sum';

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;
use Graph::Maker::QuartetTree;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # Lushbaugh map is 3-colourable

  my $n = 4;
  my $graph = graph($n);
   MyGraphs::Graph_view($graph);

  # my ($a,$b,$c) = MyGraphs::Graph_find_triangle($graph);
  my ($a,$b,$c) = ('0,-2', '-1.5,-4.5', '1.5,-4.5');
  my %colours = ($a => 1, $b => 2, $c => 3);
  my $more = 1;
  while ($more) {
    print "assigned ",scalar(keys %colours)," vertices\n";
    ### %colours
    $more = 0;
    foreach my $a ($graph->vertices) {
      $colours{$a} || next;
      foreach my $b ($graph->vertices) {
        next if $a eq $b;
        $colours{$b} || next;
        next if $colours{$a} == $colours{$b};
        ### a: "$a  ".($colours{$a}//'undef')
        ### b: "$b  ".($colours{$b}//'undef')
        my @neighbours = $graph->neighbours($a);
        foreach my $c (@neighbours) {
          next if $c eq $b;
          next if ! $graph->has_edge($b,$c);
          ### c: "$c  ".($colours{$c}//'undef')
          my $s = three_colour_other($colours{$a},$colours{$b});
          if ($colours{$c}) {
            $s == $colours{$c}
              or die "oops, recolour $s vs $colours{$c} on $c";
          } else {
            $colours{$c} = $s; $more = 1;
          }
        }
      }
    }

    if (! $more) {
    A: foreach my $a ($graph->vertices) {
        next if $colours{$a};
        my @neighbours = $graph->neighbours($a);
        @neighbours || die;
        my $colour = 0;
        foreach my $neighbour (@neighbours) {
          my $neighbour_colour = $colours{$neighbour} // next;
          if ($colour) {
            if ($colour != $neighbour_colour) { next A; }
          } else {
            $colour = $colours{$neighbour};
          }
        }
        foreach my $neighbour (@neighbours) {
          my $neighbour_colour = $colours{$neighbour} // next;
          $colours{$a} = colour_other($neighbour_colour);
          last;
        }
        $more = 1;
      }
    }
  }

  ### %colours
  print "final ",scalar(keys %colours)," vertices\n";

  my $bad = 0;
  foreach my $v ($graph->vertices) {
    unless ($colours{$v}) {
      print "no colour $v\n";
      $bad++;
    }
  }
  die if $bad;
  foreach my $edge ($graph->edges) {
    my ($from,$to) = @$edge;
    unless ($colours{$from} != $colours{$to}) {
      print "$from to $to colours $colours{$from} and $colours{$to}\n";
      $bad++;
    }
  }
  die if $bad;
  print "ok\n";
  exit 0;

  sub colour_other {
    my ($a) = @_;
    if (! defined $a) { die "colour_other() oops, got undef" }
    if ($a==1) { return 2; }
    if ($a==2) { return 3; }
    if ($a==3) { return 1; }
    die;
  }
  sub three_colour_other {
    my ($a,$b) = @_;
    if ($a==1 && $b==2) { return 3; }
    if ($a==2 && $b==3) { return 1; }
    if ($a==3 && $b==1) { return 2; }
    if ($a==2 && $b==1) { return 3; }
    if ($a==3 && $b==2) { return 1; }
    if ($a==1 && $b==3) { return 2; }
    die;
  }
  CHECK {
    three_colour_other(1,2) == 3 or die;
    three_colour_other(2,3) == 1 or die;
    three_colour_other(3,1) == 2 or die;
  }
}
{
  # Lushbaugh map chromatic number timeout
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30681

  require File::Slurp;
  foreach my $filename (glob("/so/hog/graphs/*.html")) {
    my $str = File::Slurp::read_file($filename);

    $str =~ /Chromatic Number.*?(\d+|Computation time out)/s or die $filename;
    my $chromatic_number = $1;

    if ($chromatic_number eq 'Computation time out') {
      print "$filename\n";
    }
  }
  print "ok\n";
  exit 0;
}

{
  # Lushbaugh map diagram view

  my $n = 5;
  my @planars = planars($n);
  my $num_pieces = scalar(@planars);
  print "n=$n pieces $num_pieces\n";

  require PostScript::Simple;
  my $ps = PostScript::Simple->new(papersize => "A4",
                                   eps => 0,
                                   units => 'cm');
  $ps->newpage;
  # $ps->setlinewidth($line_width);

  my $scale = .4;
  my $ox = 10;
  my $oy = 12;
  my $transform = sub {
    my ($x,$y) = @_;
    $x *= $scale;
    $y *= $scale;
    $x += $ox;
    $y += $oy;
    return ($x,$y);
  };

  foreach my $planar (@planars) {
    my $points = $planar->points;
    ### $points
    $ps->polygon({filled=>0},
                 map {$transform->(@$_)} @$points, $points->[0]);
  }
  $ps->output('/tmp/x.ps');
  require IPC::Run;
  IPC::Run::run(['gv','--scale','.8','/tmp/x.ps']);
  exit 0;
}


{
  # Lushbaugh map HOG

  my @graphs;
  foreach my $n (5) {
    my $graph = graph($n);

    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    print "n=$n  $num_vertices vertices $num_edges edges\n";
    # MyGraphs::Graph_view($graph);

    my $can = MyGraphs::graph6_str_to_canonical
      (MyGraphs::Graph_to_graph6_str($graph));
    print MyGraphs::hog_grep($can)?"  HOG yes":"  HOG not", "\n";

    print "\n";
    push @graphs, $graph;
  }
  MyGraphs::hog_searches_html(@graphs);
  exit 0;
}


{
  # graph view
  my $n = 5;
  my $graph = graph($n);
  MyGraphs::Graph_view($graph);
  exit 0;
}


# Map graph of the proof without words diagram by Warren Lushbaugh showing
# (1+2+3+4+...+n)^2 = 1^3 + 2^3 + 3^3 + 4^3 + ... + n^3.  Each vertex is a
# square area of the diagram.  Edges are between areas with a common
# boundary (not those touching at just a point).
# 
# Solomon W. Golomb, Mathematical Gazette, volume 49, number 368, May 1965,
# pages 198-200.  https://www.jstor.org/stable/3612319
# Shown also in Knuth, volume 1, section 1.2.1, exercise 8, second edition
# page 19 (with errata correcting to Lushbaugh).
#
# n=5
# https://hog.grinvin.org/ViewGraphInfo.action?id=30681
#
sub graph {
  my ($n) = @_;
  my @planars = planars($n);

  my @names;
  my %names_seen;
  foreach my $planar (@planars) {
    my ($x,$y);
    if (1 && $planar->isconvex) {
      ($x,$y) = @{$planar->centroid};
    } else {
      my $points = $planar->points;
      $x = min(map {$_->[0]} @$points) + 1;
      $y = min(map {$_->[1]} @$points) + 1;
    }
    my $name = "$x,$y";
    if ($names_seen{$name}++) {
      die "oops, duplicate name $name";
    }
    push @names, $name;
  }

  require Graph;
  my $graph = Graph->new (undirected => 1);
  $graph->set_graph_attribute('vertex_name_type_xy', 1);

  require MyPlanar;
  foreach my $i (0 .. $#planars) {
    foreach my $j ($i+1 .. $#planars) {
      my $ipoints = $planars[$i]->points;
      my $jpoints = $planars[$j]->points;
      my @upoints = MyPlanar::poly_union($ipoints,$jpoints);
      ### ipoints: "i=$i ".points_str($ipoints)
      ### jpoints: "j=$j ".points_str($jpoints)
      ### upoints count: scalar(@upoints)
      ### upoints 0: points_str($upoints[0])
      (@upoints == 1 || @upoints == 2) or die;
      next if @upoints == 2;
      my %seen;
      my $duplicate = 0;
      foreach my $p (@{$upoints[0]}) {
        if ($seen{point_str($p)}++) { $duplicate = 1; }
      }
      next if $duplicate;
      $graph->add_edge ($names[$i],$names[$j]);
    }
  }
  return $graph;
}

# Return a list of Math::Geometry::Planar objects which are the map polygon
# pieces, in no particular order.
#
sub planars {
  my ($n) = @_;
  require Math::Geometry::Planar;
  my @planars;

  my $x = 0;      # top right corner
  my $y = 0;
  foreach my $size (1 .. $n) {

    $x += $size;
    $y += $size;
    my $dx = -$size;
    my $dy = 0;
    foreach (1 .. 4) {
      ### at: "$x,$y size $size"
      my ($lx,$ly) = xy_rotate_plus90($dx,$dy);
      foreach (1 .. $size) {
        push @planars, points_to_planar([ [$x,$y],
                                          [$x    +$dx,$y    +$dy],
                                          [$x+$lx+$dx,$y+$ly+$dy],
                                          [$x+$lx,    $y+$ly] ]);
        $x += $dx;
        $y += $dy;
      }
      $x += $dx;
      $y += $dy;
      ($dx,$dy) = ($lx,$ly);
    }
    ### final: "$x,$y"
  }
  # $x == sum(1..$n) || die;
  # $y == sum(1..$n) || die;

  if (1) {
    my $area = sum(map {$_->area} @planars);
    my $w = 2*$x;
    my $h = 2*$y;
    $area == 4*$x*$y or die;

    require MyPlanar;
    foreach my $i (0 .. $#planars) {
      foreach my $j ($i+1 .. $#planars) {
        if (planar_any_overlap($planars[$i], $planars[$j])) {
          die "$i $j overlap"; # area $iarea + $jarea != $uarea";
        }
      }
    }
  }

  return @planars;
}
sub planar_any_overlap {
  my ($planar1, $planar2) = @_;
  my $points1 = $planar1->points;
  my $points2 = $planar2->points;
  my @upoints = MyPlanar::poly_union($points1,$points2);
  @upoints >= 1 or die;
  if (@upoints >= 2) { return 0; }  # no touch at all
  my $upoints = $upoints[0];
  # ### $i
  # ### $j
  # ### $ipoints
  # ### $jpoints
  # ### $upoints
  # ### @upoints
  my $area1 = MyPlanar::points_to_area($points1);
  my $area2 = MyPlanar::points_to_area($points2);
  my $uarea = MyPlanar::points_to_area($upoints);
  ### $area1
  ### $area2
  ### $uarea
  return ($uarea != $area1 + $area2);
}

sub points_to_planar {
  my ($points) = @_;
  my $planar = Math::Geometry::Planar->new;
  $planar->points($points);
  return $planar;
}

sub xy_rotate_plus90 {
  my ($x,$y) = @_;
  return (-$y,$x);  # rotate +90
}
sub xy_rotate_minus90 {
  my ($x,$y) = @_;
  return ($y,-$x);  # rotate -90
}

# $points is an arrayref of [$x,$y] pairs.
# Return a string "x,y x,y ...".
sub points_str {
  my ($points) = @_;
  if (! defined $points) { return "undef"; }
  if (@$points == 0) { return "(empty)"; }
  return join(' ',map{point_str($_)} @$points);
}
# $p is an arrayref pair [$x,$y].
# Return a string "x,y".
sub point_str {
  my ($p) = @_;
  return  join(',',@$p);
}
