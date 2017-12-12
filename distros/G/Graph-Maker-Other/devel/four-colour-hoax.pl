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

use strict;
use 5.010;
use List::Util 'min','sum';

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
# use Smart::Comments;


{
  # https://hog.grinvin.org/ViewGraphInfo.action?id=30320

  # http://www.hakank.org/common_cp_models/
  # http://www.hakank.org/minizinc/color.mzn
  # http://www.hakank.org/picat/color.pi

  # http://www.picat-lang.org/bprolog/example.html
  # http://www.picat-lang.org/bprolog/examples/clpfd/color.pl

  # http://bach.seg.kobe-u.ac.jp/llp/examples/color.llp [gone]

  # Chris Thompson, sci.math 1996 ascii art
  # http://web.archive.org/web/1id_/http://www.math.niu.edu/~rusin/known-math/96/gardner.4color

  # http://www.logic-books.info/sites/default/files/k12-time_travel_and_other_matematical_bewilderments.pdf

  # M500 magazine, Problem 198.8 "Four Colours" (drawn turned 90deg)
  # M198WEB.pdf

  my $graph = graph();
  {
    my $num_vertices = $graph->vertices;
    my $num_edges = $graph->edges;
    print "$num_vertices vertices $num_edges edges\n";
  }
  # MyGraphs::Graph_view($graph);

  my $can = MyGraphs::graph6_str_to_canonical
    (MyGraphs::Graph_to_graph6_str($graph));
  print MyGraphs::hog_grep($can)?"HOG yes":"HOG not", "\n";

  print "minizinc\n";
  my $minizinc = minizinc();
  print MyGraphs::Graph_is_isomorphic($graph,$minizinc) ? "yes" : "no", "\n";

  my $picat_by_neighbours = picat_by_neighbours();
  {
    my $num_vertices = $picat_by_neighbours->vertices;
    my $num_edges = $picat_by_neighbours->edges;
    print "picat neighbours $num_vertices/$num_edges\n";
  }
  print MyGraphs::Graph_is_isomorphic($graph,$picat_by_neighbours) ? "yes" : "no", "\n";
  # print MyGraphs::Graph_is_isomorphic($minizinc, $picat_by_edges) ? "yes" : "no", "\n";

  my $bprolog = bprolog();
  {
    my $num_vertices = $picat_by_neighbours->vertices;
    my $num_edges = $picat_by_neighbours->edges;
    print "bprolog neighbours $num_vertices/$num_edges\n";
  }
  print MyGraphs::Graph_is_isomorphic($graph,$bprolog) ? "yes" : "no", "\n";

  print "\n";
  my $picat_by_edges = picat_by_edges();
  {
    my $num_vertices = $picat_by_edges->vertices;
    my $num_edges = $picat_by_edges->edges;
    print "picat edges $num_vertices/$num_edges\n";
  }
  # print MyGraphs::Graph_is_isomorphic($graph,$picat_by_edges) ? "yes" : "no", "\n";
  # print MyGraphs::Graph_is_isomorphic($picat_by_edges,$picat_by_neighbours) ? "yes" : "no", "\n";

  MyGraphs::hog_searches_html($graph);
  exit 0;
}
{
  my @planars = planars();
  my $num_pieces = scalar(@planars);

  require PostScript::Simple;
  my $ps = PostScript::Simple->new(papersize => "A4",
                                   eps => 0,
                                   units => 'cm');
  $ps->newpage;
  # $ps->setlinewidth($line_width);

  my $scale = .4;
  my $ox = 2;
  my $oy = 6;
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

sub bprolog {
  require File::Slurp;
  my $str = File::Slurp::read_file("$ENV{HOME}/HOG/color.pl");
  require Graph;
  my $graph = Graph->new (undirected => 1);
  my $from = 1;
  while ($str =~ /neighbors\(([0-9]+),\[([0-9,]*)/g) {
    my $from = $1;
    my $to_str = $2;
    foreach my $to (split /,/, $to_str) {
      $graph->add_edge($from,$to);
    }
  }
  return $graph;
}
sub minizinc {
  require File::Slurp;
  my $str = File::Slurp::read_file("$ENV{HOME}/HOG/color.mzn");
  require Graph;
  my $graph = Graph->new (undirected => 1);
  my $from = 1;
  while ($str =~ /\{([0-9,]*)\}/g) {
    my $to_str = $1;
    foreach my $to (split /,/, $to_str) {
      $graph->add_edge($from,$to);
    }
    $from++;
  }
  return $graph;
}
sub picat_by_edges {
  require File::Slurp;
  my $str = File::Slurp::read_file("$ENV{HOME}/HOG/color.pi");
  require Graph;
  my $graph = Graph->new (undirected => 1);
  my $from = 1;
  while ($str =~ /^edge\(([0-9,]+)/mg) {
    $graph->add_edge(split /,/, $1);
  }
  return $graph;
}
sub picat_by_neighbours {
  require File::Slurp;
  my $str = File::Slurp::read_file("$ENV{HOME}/HOG/color.pi");
  require Graph;
  my $graph = Graph->new (undirected => 1);
  my $from = 1;
  while ($str =~ /neighbors\(([0-9]+),\[([0-9,]*)/g) {
    my $from = $1;
    my $to_str = $2;
    foreach my $to (split /,/, $to_str) {
      $graph->add_edge($from,$to);
    }
  }
  return $graph;
}

sub graph {
  my @planars = planars();

  my @names;
  my %names_seen;
  foreach my $planar (@planars) {
    my ($x,$y);
    if (0 && $planar->isconvex) {
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
      (@upoints == 1 || @upoints == 2) or die;
      if (@upoints == 1) {
        $graph->add_edge ($names[$i],$names[$j]);
      }
    }
  }
  return $graph;
}

# Return a list of Math::Geometry::Planar objects which are the map polygon
# pieces, in no particular order.
#
sub planars {
  require Math::Geometry::Planar;

  my $w = 42;
  my $h = 46;
  my $xmid = $w/2;
  my $ymid = $h/2;

  my @planars;

  # 2x1 bricks
  my $blocks = 8;
  foreach my $i (0 .. $blocks-1) {
    my $y = 2 + 2*$i;
    foreach my $j (0 .. $blocks-1-$i) {
      my $x = 4 + 2*$i + 4*$j;
      push @planars, points_to_planar([ [$x,$y], [$x+4,$y],
                                        [$x+4,$y+2], [$x,$y+2] ]);
      push @planars, points_to_planar([ [$x,$h-$y], [$x+4,$h-$y],
                                        [$x+4,$h-$y-2], [$x,$h-$y-2] ]);
    }
  }

  # middle rectangle
  push @planars, points_to_planar([ [$w/2-3, $h/2+3], [$w/2+1, $h/2+3],
                                    [$w/2+1, $h/2-3], [$w/2-3, $h/2-3] ]);

  # top left
  foreach my $i (0 .. $blocks-1) {
    my $x = 2 + 2*$i;  # top left of each L shape
    my $y = $h - (4 + 2*$i);
    push @planars, points_to_planar([ [$x,$y], [$x+4,$y],
                                      [$x+4,$y-2], [$x+2,$y-2],
                                      [$x+2, $ymid], [$x,$ymid] ]);
  }

  # bottom left
  foreach my $i (0 .. $blocks) {
    my $x = 4 + 2*$i;  # bottom right corner
    my $y = 2 + 2*$i;
    my $a = $x - 3 + ($i==0);       # left vertical
    my $b = $x - 1 - ($i==$blocks); # right vertical
    push @planars, points_to_planar([ [$x,$y], [$a,$y], [$a,$ymid],
                                      [$b,$ymid], [$b,$y+2], [$x,$y+2] ]);

  }

  # top right
  foreach my $i (0 .. $blocks) {
    my $x = $w - 2 - 2*$i;  # top right corner
    my $y = $h - 2 - 2*$i;
    push @planars, points_to_planar([ [$x,$y], [$x-4,$y],
                                      [$x-4,$y-2], [$x-2,$y-2],
                                      [$x-2,$ymid],[$x,$ymid] ]);
  }

  # bottom right
  foreach my $i (1 .. $blocks) {
    my $x = $w - 6 - 2*$i;  # bottom left corner
    my $y = 2 + 2*$i;
    my $a = $x + 1 + ($i==$blocks);       # left vertical
    my $points = [ [$x,$y], [$x+3,$y], [$x+3,$ymid],
                   [$a,$ymid], [$a,$y+2], [$x,$y+2] ];
    push @planars, points_to_planar($points);
  }

  # bottom right rectangle
  push @planars, points_to_planar([ [$xmid+1,0], [$w,0], [$w,2], [$xmid+1,2] ]);

  # left and bottom
  push @planars, points_to_planar([ [0,0], [$xmid+1,0], [$xmid+1,2],
                                    [2,2], [2,$h-4], [4,$h-4], [4,$h-2],
                                    [0,$h-2] ]);

  # right and across top
  push @planars, points_to_planar([ [$w,2], [$w,$h], [0,$h],
                                    [0,$h-2], [$w-2,$h-2], [$w-2,$ymid],
                                    [$w-5,$ymid], [$w-5,4], [$w-6,4],
                                    [$w-6,2]]);
  if (1) {
    my $area = sum(map {$_->area} @planars);
    $area == $w*$h or die;

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
