#!/usr/bin/perl -w

# Copyright 2018, 2019 Kevin Ryde
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
# before warnings checking since Graph.pm 0.96 is not safe to non-numeric
# version number from Storable.pm
use Graph;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

plan tests => 33156;

use FindBin;
use lib "$FindBin::Bin/../..";

require Graph::Maker::Permutations;


#------------------------------------------------------------------------------
{
  my $want_version = 13;
  ok ($Graph::Maker::Permutations::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Permutations->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Permutations->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Permutations->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}


#------------------------------------------------------------------------------
# Helpers

sub factorial {
  my ($n) = @_;
  my $ret = 1;
  foreach my $i (2 .. $n) {
    $ret *= $i;
  }
  return $ret;
}
ok (factorial(0), 1);
ok (factorial(1), 1);
ok (factorial(2), 2);
ok (factorial(3), 6);
ok (factorial(4), 24);


#------------------------------------------------------------------------------
# _vertex_name_type_cycles()

{
  my $aref = [1,2,3,4];
  my @postorder = Graph::Maker::Permutations::_vertex_name_type_cycles($aref);
  ok (join(',',@postorder), '(1)(2)(3)(4)');
}
{
  my $aref = [4,3,2,1];
  my @postorder = Graph::Maker::Permutations::_vertex_name_type_cycles($aref);
  ok (join(',',@postorder), '(1,4)(2,3)');
}
{
  my $aref = [2,1,3,4];
  my @postorder = Graph::Maker::Permutations::_vertex_name_type_cycles($aref);
  ok (join(',',@postorder), '(1,2)(3)(4)');
}
{
  my $aref = [2,3,1];
  my @postorder = Graph::Maker::Permutations::_vertex_name_type_cycles($aref);
  ok (join(',',@postorder), '(1,2,3)');
}

#------------------------------------------------------------------------------
# Specifics

{
  # N=0
  my $graph = Graph::Maker->new ('permutations', N=>0);
  ok (scalar($graph->vertices), 1);
  ok (scalar($graph->edges), 0);
}


#------------------------------------------------------------------------------
exit 0;
