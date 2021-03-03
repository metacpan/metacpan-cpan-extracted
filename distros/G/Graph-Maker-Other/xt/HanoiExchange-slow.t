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

use Graph::Maker::HanoiExchange;

use File::Spec;
use lib File::Spec->catdir('devel','lib');
use MyGraphs 'Graph_is_isomorphic';

plan tests => 117;

# uncomment this to run the ### lines
# use Smart::Comments;


#------------------------------------------------------------------------------
# POD HOG Shown

{
  my %shown;
  {
    my $content = File::Slurp::read_file
      (File::Spec->catfile($FindBin::Bin,
                           File::Spec->updir,
                           'lib','Graph','Maker','HanoiExchange.pm'));
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
    ok ($count, 6, 'HOG ID parsed matches');
  }
  ok (scalar(keys %shown), 6);
  ### %shown

  my $extras = 0;
  my $compared = 0;
  my $others = 0;
  my %g6_seen;
  my %uncompared = %shown;
  foreach my $discs (0 .. 5) {
    foreach my $spindles (3 .. ($discs<=1 ? 3
                                : 6+2-$discs)) {
      my $graph = Graph::Maker->new('hanoi_exchange', undirected => 1,
                                    discs => $discs,
                                    spindles => $spindles);
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

# 3 spindles solution length f(n)
sub f {
  my ($n) = @_;
  $n >= 0 or croak "f is for n>=3";
  if ($n == 0) { return 0; }
  if ($n == 1) { return 1; }
  if ($n == 2) { return 3; }
  if ($n == 3) { return 7; }
  return f($n-1) + f($n-2) + 2*f($n-4) + 3;
}
memoize('f', LIST_CACHE => 'MERGE');
{
  my @want = (0,1,3,7,13,25,47,89,165,307,569,1057,1959,3633,6733,12483);
  foreach my $n (0 .. $#want) {
    ok (f($n), $want[$n]);
  }
}

sub g {
  my ($n) = @_;
  $n >= 0 or croak "g is for n>=3";
  return ($n==0 ? 0 : g($n-1) + h($n-1) + 1);
}
memoize('g', LIST_CACHE => 'MERGE');
{
  my @want = (0,1,3,6,12,23,44,82,153,284,528,979,1816,3366,6241,11568,21444);
  foreach my $n (0 .. $#want) {
    ok (g($n), $want[$n]);
  }
}

sub h {
  my ($n) = @_;
  $n >= 0 or croak "g is for n>=3";
  return ($n==0 ? 0
          : $n==1 ? 1
          : f($n-2) + g($n-1) + 1);
}
memoize('h', LIST_CACHE => 'MERGE');
{
  my @want = (0,1,2,5,10,20,37,70,130,243,450,836,1549,2874,5326,9875,18302);
  foreach my $n (0 .. $#want) {
    ok (h($n), $want[$n]);
  }
}

foreach my $N (0 .. 4) {
  my $graph = Graph::Maker->new('hanoi_exchange',
                                discs => $N,
                                undirected => 1);
  my $want = f($N);
  {
    my @vertices = $graph->vertices;
    my $got = $graph->path_length(min(@vertices), max(@vertices)) || 0;
    ok ($got,$want, "N=3 diameter");
  }
  {
    my $got = $graph->diameter||0;
    ok ($got,$want, "N=3 diameter");
  }

  if ($N==4) {
    { # g X^n to YZ^(n-1)
      my $from = cnv('0000',3,10);
      my $to   = cnv('1222',3,10);
      ok (!! $graph->has_vertex($from), 1);
      ok (!! $graph->has_vertex($to), 1);
      ok ($graph->path_length($from,$to), g(4));
    }
    { # h
      my $from = cnv('0000',3,10);
      my $to   = cnv('1000',3,10);
      ok (!! $graph->has_vertex($from), 1);
      ok (!! $graph->has_vertex($to), 1);
      ok ($graph->path_length($from,$to), h(4));
    }
    { # h(3)
      my $from = cnv('2000',3,10);
      my $to   = cnv('2100',3,10);
      ok (!! $graph->has_vertex($from), 1);
      ok (!! $graph->has_vertex($to), 1);
      ok ($graph->path_length($from,$to), h(3));
    }
  }
}

#------------------------------------------------------------------------------
# Geometric Distances

sub d_cross {
  my ($n) = @_;
  return ($n==0,1, 2**($n-1));
}
# from 1222 out to 10222
foreach my $N (1 .. 8) {
  my $from = cnv('01'.('2' x ($N-1)), 3,10);  # 01 22..22
  my $to   = cnv('10'.('2' x ($N-1)), 3,10);  # 10 22..22
  my $distance = xyxy_to_distance(vertex_to_xy($from),
                                  vertex_to_xy($to));
  ok ($distance, d_cross($N));
}

sub uv_is_small_move {
  my ($u,$v) = @_;
  return int($u/3) == int($v/3);
}
foreach my $N (0 .. 5) {
  ### $N
  my $graph = Graph::Maker->new('hanoi_exchange',
                                discs => $N,
                                undirected => 1);
  my @vertices = $graph->vertices;
  my @path = $graph->path_vertices(min(@vertices), max(@vertices));
  if ($N==0) {
    ok (scalar(@vertices), 1);
    if (@path == 0) { @path = @vertices; }
  }
  my $want = f($N);
  ok (scalar(@path), $want+1);

  my ($x,$y) = vertex_to_xy($path[0]);
  my $distance = 0;
  foreach my $i (1 .. $#path) {
    my ($x2,$y2) =vertex_to_xy($path[$i]);
    $distance += xyxy_to_distance($x,$y, $x2,$y2);
    ($x,$y) = ($x2,$y2);
  }
  ok ($distance,d_distance($N), "N=$N d_distance()");

  my @moves = map {uv_is_small_move($path[$_],$path[$_-1])||0} 1 .. $#path;
  ok (scalar(@moves), f($N));
  my $num_moves     = sum(0, @moves);
  my $num_exchanges = scalar(@moves) - $num_moves;
  ok ($num_exchanges, $N==0 ? 0 : f($N-1));
  ok ($num_moves,     $N==0 ? 0 : f($N) - f($N-1));
  # MyTestHelpers::diag("N=$N moves: ",join(',',@moves));
}

# d(n) geometric distance for the solution
sub d_distance {
  my ($n) = @_;
  return (7*2**$n - f($n+3) + f($n))/2;
}

sub xyxy_to_distance {
  my ($x,$y, $x2,$y2) = @_;
  my $dx = abs($x - $x2);
  my $dy = abs($y - $y2);
  if ($dy == 0) {
    $dx %2 == 0 or die;
    return $dx/2;
  } else {
    $dx == $dy or die;
    return $dy;
  }
}

# for 3 spindles
sub vertex_to_xy {
  my ($v) = @_;
  my $str = cnv($v,10,3);
  my $x = 0;
  my $y = 0;
  my @digits = reverse split //, $str;   # low to high
  foreach my $i (0 .. $#digits) {
    my $d = $digits[$i];
    if ($d == 1) { $x -= 1<<$i; }
    if ($d == 2) { $x += 1<<$i; }
    if ($d) { $y -= 1<<$i; }
  }
  return ($x,$y);
}


#------------------------------------------------------------------------------
# spindles=3 discs <= 2 isomorphic to plain Hanoi, and otherwise not

{
  require Graph::Maker::Hanoi;
  my $spindles = 3;
  foreach my $discs (0 .. 4) {
    my $plain = Graph::Maker->new('hanoi',
                                discs => $discs, spindles => $spindles,
                                undirected => 1);
    my $exchange = Graph::Maker->new('hanoi_exchange',
                                   discs => $discs, spindles => $spindles,
                                   undirected => 1);
    my $got = Graph_is_isomorphic($plain, $exchange) ? 1 : 0;
    my $want = $discs<=2 ? 1 : 0;
    ok ($got, $want);
  }
}

#------------------------------------------------------------------------------
exit 0;
