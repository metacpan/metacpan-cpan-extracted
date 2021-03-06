#!/usr/bin/perl -w

# Copyright 2015, 2017 Kevin Ryde
#
# This file is part of Graph-Graph6.
#
# Graph-Graph6 is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Graph-Graph6 is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with Graph-Graph6.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

my $test_count = (tests => 36)[1];
plan tests => $test_count;

# uncomment this to run the ### lines
# use Smart::Comments;


require Graph::Graph6;

{
  my $have_taint_util = eval { require Taint::Util; 1 };
  my $have_taint_util_error = $@;
  if (! $have_taint_util) {
    MyTestHelpers::diag ('Skip due to no Taint::Util available: ',
                         $have_taint_util_error);
    foreach (1 .. $test_count) {
      skip ('no Taint::Util', 1, 1);
    }
    exit 0;
  }
}

{
  my $str = 'hello';
  Taint::Util::taint($str);
  if (! Taint::Util::tainted($str)) {
    MyTestHelpers::diag ('Skip due to not running in perl -T taint mode');
    foreach (1 .. $test_count) {
      skip ('due to not running in perl -T taint mode', 1, 1);
    }
    exit 0;
  }
}


#------------------------------------------------------------------------------
# read_graph()

my $graph6_filename  = 'Graph-Graph6-taint-graph6.tmp';
my $sparse6_filename = 'Graph-Graph6-taint-sparse6.tmp';
my $digraph6_filename = 'Graph-Graph6-taint-digraph6.tmp';

my $graph6_str  = chr(68).chr(81).chr(99)."\n";
my $sparse6_str = ':Fa@x^';
my $digraph6_str = chr(38).chr(68).chr(73).chr(63).chr(65).chr(79).chr(63)."\n";
{
  open my $fh, '>', $graph6_filename or die;
  print $fh $graph6_str or die;
  close $fh or die;
}
{
  open my $fh, '>', $sparse6_filename or die;
  print $fh $sparse6_str or die;
  close $fh or die;
}
{
  open my $fh, '>', $digraph6_filename or die;
  print $fh $digraph6_str or die;
  close $fh or die;
}
Taint::Util::taint($graph6_str);
Taint::Util::taint($sparse6_str);
Taint::Util::taint($digraph6_str);

open my $graph6_fh, '<', $graph6_filename or die;
open my $sparse6_fh, '<', $sparse6_filename or die;
open my $digraph6_fh, '<', $digraph6_filename or die;

foreach my $elem (
                  ["filename graph6",   filename => $graph6_filename ],
                  ["filename sparse6",  filename => $sparse6_filename ],
                  ["filename digraph6", filename => $digraph6_filename ],
                  ["fh graph6",         fh => $graph6_fh ],
                  ["fh sparse6",        fh => $sparse6_fh ],
                  ["fh digraph6",       fh => $digraph6_fh ],
                  ["str graph6",        str => $graph6_str ],
                  ["str sparse6",       str => $sparse6_str ],
                  ["str digraph6",      str => $digraph6_str ],
                 ) {
  my ($name, @options) = @$elem;

  my @edges;
  my @edges_func;
  my $num_vertices;
  my $num_vertices_func;
  my $ret = Graph::Graph6::read_graph
    (@options,
     num_vertices_ref => \$num_vertices,
     num_vertices_func => sub {
       my ($n) = @_;
       $num_vertices_func = $n;
     },
     edge_func => sub {
       push @edges_func, [@_];
     },
     edge_aref => \@edges,
    );
  ok (!! Taint::Util::tainted($num_vertices),      1, "$name: num_vertices tainted");
  ok (!! Taint::Util::tainted($num_vertices_func), 1, "$name: num_vertices_func tainted");

  foreach my $edge_aref (\@edges, \@edges_func) {
    my $edges_tainted = 1;
    foreach my $edge (@edges) {
      foreach my $v (@$edge) {
        if (! Taint::Util::tainted($v)) {
          MyTestHelpers::diag("edge vertex $v untained");
          $edges_tainted = 0;
        }
      }
    }
    ok (!! $edges_tainted, 1, "$name: all edge numbers tainted");
  }
}

#------------------------------------------------------------------------------
unlink $graph6_filename;
unlink $sparse6_filename;

exit 0;
