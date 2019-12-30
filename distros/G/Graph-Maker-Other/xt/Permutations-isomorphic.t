#!/usr/bin/perl -w

# Copyright 2017, 2018, 2019 Kevin Ryde
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
use FindBin;
use File::Spec;
use File::Slurp;
use Test;
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use Math::BaseCnv 'cnv';
use Math::NumSeq::Catalan;
use Math::NumSeq::BalancedBinary;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use Graph::Maker::Permutations;
use MyGraphs;

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 21;

my $seq = Math::NumSeq::BalancedBinary->new;

my @rel_types
  = ('transpose',
     'transpose_cover',
     'transpose_adjacent',
     'transpose_cyclic',
     'transpose_plus1',
     'onepos',
     # 'cycle_append'
    );
ok (scalar(@rel_types), 6);

my @vertex_name_types
  = ('perm',
     # 'perm_inverse',
     'cycles',
    );
ok (scalar(@vertex_name_types), 2);


#------------------------------------------------------------------------------
# Distinct rel_type to Isomorphism

foreach my $N (4,5) {
  foreach my $inverse (0,1) {
    my %g6_to_rel_types;
    my %str_to_rel_types;
    foreach my $rel_type (@rel_types) {
      my $graph = Graph::Maker->new('permutations', N => $N,
                                    rel_type   => $rel_type,
                                    vertex_name_inverse => $inverse,
                                    undirected => 1);
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      push @{$g6_to_rel_types{$g6_str}}, $rel_type;
      push @{$str_to_rel_types{"$graph"}}, $rel_type;
    }

    # 10 different, per POD
    ok (scalar(@rel_types),             6);
    ok (scalar(keys %str_to_rel_types), 6);
    ok (scalar(keys %g6_to_rel_types),  5);

    my @sames = sort map {join(' = ',@$_)} values %g6_to_rel_types;
    ok (join("\n",@sames),
        "onepos
transpose
transpose_adjacent = transpose_plus1
transpose_cover
transpose_cyclic");

    # foreach my $same (@sames ) {
    #   print "$same\n";
    # }
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
                           'devel',
                           'lib','Graph','Maker','Permutations.pm'));
    $content =~ /=head1 HOUSE OF GRAPHS.*?=head1/s or die;
    $content = $&;
    my $rel_type;
    my $count = 0;
    while ($content =~ /^    (?<rel>\w+)|^      (?<id>\d+) +N=(?<N>\d+)/mg) {
      if (defined $+{'rel'}) {
        $rel_type = $+{'rel'};
      } else {
        $count++;
        my $N = $+{'N'};
        foreach my $t
          ($rel_type eq 'all' ? @rel_types
           : $rel_type eq 'transpose_adjacent' ? ($rel_type,'transpose_plus1')
           : $rel_type) {
          $shown{"N=$N,$t"} = $+{'id'};
          if ($N eq '0') {     # "N=0 and N=1"
            $shown{"N=1,$t"} = $+{'id'};
          }
        }
      }
    }
    ok ($count, 12, 'HOG ID number lines');
  }
  ok (scalar(keys %shown), 30);
  ### %shown

  my $extras = 0;
  my %seen;
  foreach my $N (0 .. 5) {      # up to 5! = 120 most for HOG
    foreach my $rel_type (@rel_types) {
      my $graph = Graph::Maker->new('permutations', N => $N,
                                    rel_type => $rel_type,
                                    undirected => 1);
      my $key = "N=$N,$rel_type";
      ### $key
      my $g6_str = MyGraphs::Graph_to_graph6_str($graph);
      $g6_str = MyGraphs::graph6_str_to_canonical($g6_str);
      if (my $id = $shown{$key}) {
        MyGraphs::hog_compare($id, $g6_str);
      } else {
        if (MyGraphs::hog_grep($g6_str)) {
          MyTestHelpers::diag ("HOG got $key, not shown in POD");
          MyTestHelpers::diag ($g6_str);
          MyGraphs::Graph_view($graph);
          $extras++
        }
      }
    }
  }
  ok ($extras, 0);
}

#------------------------------------------------------------------------------
exit 0;
