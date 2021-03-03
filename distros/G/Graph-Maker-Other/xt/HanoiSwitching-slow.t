#!/usr/bin/perl -w

# Copyright 2021 Kevin Ryde
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
use Carp 'croak';
use FindBin;
use File::Spec;
use File::Slurp;
use List::Util 'min','max','sum';
use Math::BaseCnv 'cnv';
use Memoize 'memoize';
use Test;

# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs 'Graph_is_isomorphic';

use Graph::Maker::HanoiSwitching;

plan tests => 29;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
# spindles=3 isomorphic to plain Hanoi

{
  require Graph::Maker::Hanoi;
  my $spindles = 3;
  foreach my $discs (0 .. 4) {
    my $plain = Graph::Maker->new('hanoi',
                                discs => $discs, spindles => $spindles,
                                undirected => 1);
    my $switching = Graph::Maker->new('hanoi_switching',
                                   discs => $discs, spindles => $spindles,
                                   undirected => 1);
    my $got = Graph_is_isomorphic($plain, $switching) ? 1 : 0;
    ok ($got, 1);
  }
}

#------------------------------------------------------------------------------
# spindles=2 isomorphic to path 2^N

{
  require Graph::Maker::Linear;
  my $spindles = 2;
  foreach my $discs (0 .. 4) {
    my $switching = Graph::Maker->new('hanoi_switching',
                                      discs => $discs, spindles => $spindles,
                                      undirected => 1);
    my $num_vertices = $switching->vertices;
    ok ($num_vertices, 2**$discs);
    {
      my $path = Graph::Maker->new('linear',
                                   N => $num_vertices,
                                   undirected => 1);
      # bug in Graph::Maker::Linear version 0.01 means path N=1 has no vertices
      $path->add_vertex(1);
      ok (scalar($path->vertices), $num_vertices);

      my $got = Graph_is_isomorphic($switching, $path) ? 1 : 0;
      ok ($got, 1, "discs=$discs spindles=2 switching is path");
    }
    {
      my $path = Graph->new(undirected => 1);
      $path->add_vertices (0 .. $num_vertices-1);
      $path->add_path (0 .. $num_vertices-1);
      ### path: "$path"
      ### switching: "$switching"
      ok ($switching eq $path, 1,
          "discs=$discs spindles=2 switching equals 0..2^N-1");
    }
  }
}

#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $filename = File::Spec->catfile
      ($FindBin::Bin, File::Spec->updir,
       'devel', 'lib','Graph','Maker','HanoiSwitching.pm');
    my $content = File::Slurp::read_file ($filename);
    $content =~ /=head1 HOUSE OF GRAPHS.*?(?==head1)/s or die;
    $content = $&;
    $content =~ s/.*?=back//s;
    ### $content
    my $count = 0;
    my $discs;
    my $spindles;
    while ($content =~ /discs=(?<discs>\d+)
                      |spindles=(?<spindles>\d+)
                      |(?<id>\d+).*$       # ID and skip remarks after
                      |(?<comment>\(For.*)
                       /mgx) {
      if (defined $+{'discs'}) { $discs = $+{'discs'}; }
      elsif (defined $+{'spindles'}) { $spindles = $+{'spindles'}; }
      elsif (defined $+{'id'}) {
        $count++;
        my $id = $+{'id'};
        ### $spindles
        ### $discs
        ### $id
        $shown{"spindles=$spindles,discs=$discs"} = $id;
      } elsif (defined $+{'comment'}) {
      } else {
        die "Unrecognised match: $&";
      }
    }
    ok ($count, 2, 'HOG ID parsed matches');
  }
  ok (scalar(keys %shown), 2);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my %g6_seen;
  my %uncompared = %shown;
  foreach my $discs (0 .. 5) {
    foreach my $spindles (4 .. ($discs<=1 ? 4
                                : 6+2-$discs)) {
      my $graph = Graph::Maker->new('hanoi_switching',
                                    discs => $discs,
                                    spindles => $spindles,
                                    undirected => 1);
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      next if $g6_seen{$g6_str}++;
      my $key = "spindles=$spindles,discs=$discs";
      if (my $id = $shown{$key}) {
        MyGraphs::hog_compare($id, $g6_str);
        delete $uncompared{$key};
        $compared++;
      } else {
        $others++;
        if (MyGraphs::hog_grep($g6_str)) {
          my $name = $graph->get_graph_attribute('name');
          MyTestHelpers::diag ("HOG $key not shown in POD");
          MyTestHelpers::diag ($name);
          MyTestHelpers::diag ($g6_str);
          MyGraphs::Graph_view($graph);
          $extras++;
        }
      }
      # last if $graph->vertices > 255;
    }
  }
  MyTestHelpers::diag ("POD HOG $compared compares, $others others");
  ok ($extras, 0);
  ok (join(' ',keys %uncompared), '', 'should be none uncompared');
}


#------------------------------------------------------------------------------
exit 0;
