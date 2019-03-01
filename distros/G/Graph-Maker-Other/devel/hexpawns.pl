#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017, 2018 Kevin Ryde
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
use List::Util 'min';

use FindBin;
use lib "$FindBin::Bin/../devel/lib";
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # Hexpawns
  # maybe not quite right

  # all:
  # 370 vertices, 559 edges, 269 290
  # exclude mirrors:
  # 194 vertices, 285 edges, 141 156
  # exclude mirrors, exclude winning positions:
  # 100 vertices, 178 edges, 82 105

  # Gardner boxes
  # 2+2+4+4+4 + 5*4 + 4+4+4+6+6 + 5*6 + 4*6 == 114
  # 3+2+4+4+3 + 3+3+2+2+2 + 2+2+1+2+1 + 2+2+2+2+3 + 2+2+2+2 == 55

  my $want_include_mirror = 0;
  my $want_include_winning = 1;
  my $want_include_right = 1;

  my $initial_str = 'bbb000www';
  my %other_player = (w=>'b', b=>'w');
  my @captures_w = ([],[],[],
                    [0,1], [0,1,2], [1,2],
                    [3,4], [3,4,5], [4,5]);
  my @captures_b = ([3,4], [3,4,5], [4,5],
                    [6,7], [6,7,8], [7,8],
                    [],[],[]);
  my %captures = (w => \@captures_w, b => \@captures_b);
  my $nexts = sub {
    my ($str, $player) = @_;
    my @ret;
    my @a = split //, $str;
    my $other = $other_player{$player};
    foreach my $from (0 .. $#a) {
      $a[$from] eq $player or next;
      foreach my $to (@{$captures{$player}->[$from]}) {
        unless ($to == $from + 3         # straight
                || $to == $from - 3
                || $a[$to] eq $other) {  # diagonal capture
          next;
        }
        my @new = @a;
        $new[$from] = '0';
        $new[$to] = $player;
        push @ret, join('',@new);
      }
    }
    return @ret;
  };
  my $winning = sub {
    my ($str) = @_;
    my @a = split //, $str;
    return $str !~ /w/ || $str !~ /b/
      || $a[0] eq 'w' || $a[1] eq 'w' || $a[2] eq 'w'
      || $a[6] eq 'b' || $a[7] eq 'b' || $a[8] eq 'b';
  };
  my $mirror = sub {
    my ($str) = @_;
    my @a = split //, $str;
    @a[0..2] = reverse @a[0..2];
    @a[3..5] = reverse @a[3..5];
    @a[6..8] = reverse @a[6..8];
    return join('',@a);
  };
  my $mirror_min = sub {
    my ($str) = @_;
    return List::Util::minstr($str, $mirror->($str));
  };
  ### mirror: $mirror->('b000w00ww')
  $mirror->('b000w00ww') eq '00b0w0ww0' or die;

  my $vertex_name = sub {
    my ($str,$player) = @_;
    return uc($player).' '.substr($str,0,3) . "\\n"
      .'- '.substr($str,3,3) . "\\n"
      .'- '.substr($str,6,3);
  };

  require Graph;
  my $graph = Graph->new (undirected=>1);
  $graph->set_graph_attribute (flow => 'south');
  my @pending = ($initial_str);

  # unless ($want_include_right) { next if $to eq 'bbbw000ww'; }

  my $player = 'w';
  my %player_edges = (w=>0, b=>0);
  while (@pending) {
    print "pending ", scalar(@pending), "\n";
    if ($player eq 'b' && @pending <= 15) {
      print "  ",join(' ',@pending),"\n";
    }
    my %new_pending;
    foreach my $from (@pending) {
      unless ($want_include_mirror) { $from eq $mirror_min->($from) or die; }
      unless ($want_include_winning) { !$winning->($from) or die; }
      next if $winning->($from);
      # next if $mirror->($from) lt $from;
      foreach my $to ($nexts->($from,$player)) {
        # ### $from
        # ### $to
        unless ($want_include_winning) { next if $winning->($to); }
        my $to = $to;
        unless ($want_include_mirror) { $to = $mirror_min->($to); }
        $graph->add_edge($vertex_name->($from,$player), $vertex_name->($to,$other_player{$player}));
        $player_edges{$player}++;
        $new_pending{$to} = 1;
      }
    }
    @pending = keys %new_pending;
    $player = $other_player{$player};
  }
  my $num_vertices = $graph->vertices;
  my $num_edges = $graph->edges;
  print "$num_vertices vertices, $num_edges edges, $player_edges{w} $player_edges{b}\n";
  print " degrees ", sort(map{$graph->degree($_)} $graph->vertices), "\n";

  if ($graph->is_undirected) {
    foreach my $vertex ($graph->vertices) {
      if ($graph->degree($vertex) == 2) {
        print " deg2 ",$vertex,"\n";
        foreach my $neighbour ($graph->neighbours($vertex)) {
          print "   to deg ",$graph->degree($neighbour),"\n";
        }
      }
    }
  }
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  exit 0;
}
