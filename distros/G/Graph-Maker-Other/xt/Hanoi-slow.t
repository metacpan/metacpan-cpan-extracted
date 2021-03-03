#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2019, 2020, 2021 Kevin Ryde
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
use FindBin;
use File::Spec;
use File::Slurp;
use Graph::Maker::Grid;

# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Graph::Maker::Hanoi;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs 'Graph_is_isomorphic','Graph_is_subgraph';

plan tests => 77;

# uncomment this to run the ### lines
# use Smart::Comments;


sub Graph_is_edge_subset {
  my ($graph,$subgraph) = @_;
  my %seen;
  @seen{map { join('--',sort @$_) } $graph->edges} = ();  # hash slice
  ### %seen
  foreach my $edge ($subgraph->edges) {
    my $key = join('--',sort @$edge);
    if (! exists $seen{$key}) {
      print "missing $key\n";
      print "$graph\n";
      print "$subgraph\n";
      return 0;
    }
  }
  return 1;
}

#------------------------------------------------------------------------------
# Linear is Edge Subset of Grid

foreach my $discs (2 .. 3) {
  foreach my $spindles (2 .. 4) {
    # MyTestHelpers::diag ("discs=$discs spindles=$spindles");
    my $linear = Graph::Maker->new('hanoi',
                                   discs => $discs, spindles => $spindles,
                                   adjacency => 'linear',
                                   undirected => 1);
    my $grid = Graph::Maker->new('grid',
                                 dims => [($spindles) x $discs],
                                 undirected => 1);
    foreach my $i (sort {$a<=>$b} $grid->vertices) {
      MyGraphs::Graph_rename_vertex($grid,$i,$i-1);
    }
    ### grid: "$grid"
    ### linear: "$linear"
    ok (Graph_is_edge_subset ($grid, $linear), 1);
  }
}

# Cyclic is Edge Subset of Cyclic Grid
foreach my $discs (2 .. 3) {
  foreach my $spindles (2 .. 4) {
    # MyTestHelpers::diag ("discs=$discs spindles=$spindles");
    my $linear = Graph::Maker->new('hanoi',
                                   discs => $discs, spindles => $spindles,
                                   adjacency => 'cyclic',
                                   undirected => 1);
    my $grid = Graph::Maker->new('grid',
                                 dims => [($spindles) x $discs],
                                 cyclic => 1,
                                 undirected => 1);
    foreach my $i (sort {$a<=>$b} $grid->vertices) {
      MyGraphs::Graph_rename_vertex($grid,$i,$i-1);
    }
    ok (Graph_is_edge_subset ($grid, $linear), 1);
  }
}

#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','Hanoi.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?(?==head1)/s or die;
    $content = $&;
    $content =~ s/.*?=back//s;
    ### $content
    my $count = 0;
    my $discs;
    my $spindles;
    my $adjacency = 'any';
    while ($content =~ /discs=(?<discs>\d+)
                      |spindles=(?<spindles>\d+)
                      |(?<adjacency>linear|cyclic|star)
                      |(?<id>\d+).*$       # ID and skip remarks after
                      |(?<comment>\(For.*)
                       /mgx) {
      if (defined $+{'discs'}) { $discs = $+{'discs'}; }
      elsif (defined $+{'spindles'}) { $spindles = $+{'spindles'}; }
      elsif (defined $+{'adjacency'}) { $adjacency = $+{'adjacency'}; }
      elsif (defined $+{'id'}) {
        $count++;
        my $id = $+{'id'};
        ### $spindles
        ### $discs
        ### $adjacency
        ### $id
        $shown{"spindles=$spindles,discs=$discs,adjacency=$adjacency"} = $id;
        $adjacency = 'any';
      } elsif (defined $+{'comment'}) {
      } else {
        die "Unrecognised match: $&";
      }
    }
    ok ($count, 24, 'HOG ID parsed matches');
  }
  ok (scalar(keys %shown), 24);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my %g6_seen;
  my %uncompared = %shown;
  foreach my $discs (0 .. 5) {
    foreach my $spindles (3 .. ($discs<=1 ? 6
                                : 6+2-$discs)) {
      my @adjacencies = ('any');
      if ($spindles >= 3 && $discs >= 1) { push @adjacencies, 'linear'; }
      if ($discs >= 2 && $spindles >= 4) { push @adjacencies, 'cyclic'; }
      if ($discs >= 2 && $spindles >= 4) { push @adjacencies, 'star'; }
      foreach my $adjacency (@adjacencies) {
        my $key = "spindles=$spindles,discs=$discs,adjacency=$adjacency";
        ### graph ...
        ### $discs
        ### $spindles
        ### $adjacency
        ### $key
        my $graph = Graph::Maker->new('hanoi', undirected => 1,
                                      discs => $discs,
                                      spindles => $spindles,
                                      adjacency => $adjacency);
        my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
        $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
        if (my $id = $shown{$key}) {
          MyGraphs::hog_compare($id, $g6_str);
          delete $uncompared{$key};
          $compared++;
        } else {
          unless ($g6_seen{$g6_str}++) {
            $others++;
            if (MyGraphs::hog_grep($g6_str)) {
              my $name = $graph->get_graph_attribute('name');
              MyTestHelpers::diag ("HOG $key not shown in POD");
              MyTestHelpers::diag ($name);
              MyTestHelpers::diag ($g6_str);
              # MyGraphs::Graph_view($graph);
              $extras++;
            }
          }
        }
        # last if $graph->vertices > 255;
      }
    }
  }
  MyTestHelpers::diag ("POD HOG $compared compares, $others others");
  ok ($extras, 0);
  ok (join(' ',keys %uncompared), '', 'should be none uncompared');
}


#------------------------------------------------------------------------------

{
  # star discs=2 spindles=4

  #           22               sub-stars low digit
  #            |
  #           20               edges between them
  #          /  \              changing high digit 0 <-> non-0
  #        23    21
  #         |    |
  #        03    01
  #       /  \  /  \
  #     13    00    31
  #      |     |     |
  #     10    02    30
  #    /  \  /  \  /  \
  #  11    12    32    33

  my $graph = Graph->new(undirected => 1);
  $graph->add_edges(['01', '21'],
                    ['20', '21'],
                    ['03', '23'],
                    ['00', '01'],
                    ['00', '02'],
                    ['02', '12'],
                    ['20', '23'],
                    ['00', '03'],
                    ['10', '12'],
                    ['30', '33'],
                    ['01', '31'],
                    ['03', '13'],
                    ['10', '11'],
                    ['30', '32'],
                    ['10', '13'],
                    ['20', '22'],
                    ['02', '32'],
                    ['30', '31']);

  my $star = Graph::Maker->new('hanoi',
                               discs => 2, spindles => 4,
                               adjacency => 'star',
                               undirected => 1,
                               vertex_names => 'digits');
  ok ($graph eq $star, 1);
}

#------------------------------------------------------------------------------

{
  # spindles<=2   any = cyclic = linear = star

  foreach my $discs (1 .. 5) {
    foreach my $spindles (1 .. 2) {
      my $any = Graph::Maker->new('hanoi',
                                  discs => $discs, spindles => $spindles,
                                  undirected => 1);
      my $cyclic = Graph::Maker->new('hanoi',
                                     discs => $discs, spindles => $spindles,
                                     adjacency => 'cyclic',
                                     undirected => 1);
      my $linear = Graph::Maker->new('hanoi',
                                     discs => $discs, spindles => $spindles,
                                     adjacency => 'linear',
                                     undirected => 1);
      my $star = Graph::Maker->new('hanoi',
                                   discs => $discs, spindles => $spindles,
                                   adjacency => 'star',
                                   undirected => 1);
      ok ($any eq $cyclic, 1);
      ok ($any eq $linear, 1);
      ok ($any eq $star, 1);
    }
  }
}

{
  # spindles=3 has any = cyclic > linear
  #                linear isomorphic star

  my $spindles = 3;
  foreach my $discs (1 .. 5) {
    my $any = Graph::Maker->new('hanoi',
                                discs => $discs, spindles => $spindles,
                                undirected => 1);
    my $cyclic = Graph::Maker->new('hanoi',
                                   discs => $discs, spindles => $spindles,
                                   adjacency => 'cyclic',
                                   undirected => 1);
    my $linear = Graph::Maker->new('hanoi',
                                   discs => $discs, spindles => $spindles,
                                   adjacency => 'linear',
                                   undirected => 1);
    my $star = Graph::Maker->new('hanoi',
                                 discs => $discs, spindles => $spindles,
                                 adjacency => 'star',
                                 undirected => 1);
    ok ($any eq $cyclic, 1);
    ok (Graph_is_edge_subset ($cyclic, $linear), 1);
    ok (Graph_is_isomorphic($linear, $star), 1);
  }
}

{
  # any >= cyclic >= linear

  foreach my $discs (1 .. 6) {
    foreach my $spindles (4 .. 6) {
      my $any = Graph::Maker->new('hanoi',
                                  discs => $discs, spindles => $spindles,
                                  undirected => 1);
      my $cyclic = Graph::Maker->new('hanoi',
                                     discs => $discs, spindles => $spindles,
                                     adjacency => 'cyclic',
                                     undirected => 1);
      my $linear = Graph::Maker->new('hanoi',
                                     discs => $discs, spindles => $spindles,
                                     adjacency => 'linear',
                                     undirected => 1);
      # my $ac = Graph_is_isomorphic($any, $cyclic)
      #   || Graph_is_subgraph($any, $cyclic)    ? 1 : 0;
      # my $cl = Graph_is_isomorphic($cyclic, $linear)
      #   || Graph_is_subgraph($cyclic, $linear) ? 1 : 0;
      my $ac = Graph_is_edge_subset ($any, $cyclic);
      my $cl = Graph_is_edge_subset ($cyclic, $linear);
      # print "$any\n";
      # print "$cyclic\n";

      ok ($cl, 1, "cyclic>=linear  discs=$discs spindles=$spindles");
      last if $any->edges >= 10_000;
    }
  }
}

#------------------------------------------------------------------------------
exit 0;
