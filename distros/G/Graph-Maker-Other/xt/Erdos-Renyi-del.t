#!/usr/bin/perl -w

# Copyright 2018 Kevin Ryde
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

use lib 'devel/lib';
use MyGraphs;

plan tests => 23;


# Erdos and Renyi, "Asymmetric Graphs", Acta Mathematica Academiae
# Scientiarum Hungaricae, volume 14, 1963, pages 295-315
# https://users.renyi.hu/~p_erdos/1963-04.pdf

# Asymmetric, can delete edge to symmetric, cannot add edge to symmetric.
# cf nautyextra devel/asymmetric-A.c
#
#  0
#
#     1     2
#
#  3     4     5    6
#
#     7     8
#
#  9
#
# https://hog.grinvin.org/ViewGraphInfo.action?id=31137
my $whole = Graph->new(undirected => 1);
$whole->add_edge(0,1); $whole->add_edge(0,2);
$whole->add_edge(1,3); $whole->add_edge(1,4);
$whole->add_edge(2,3); $whole->add_edge(2,4); $whole->add_edge(2,5);
$whole->add_edge(2,8);
$whole->add_edge(3,4); $whole->add_edge(3,8); $whole->add_edge(3,9);
$whole->add_edge(4,5); $whole->add_edge(4,7); $whole->add_edge(4,8);
$whole->add_edge(5,6);
$whole->add_edge(6,8);
$whole->add_edge(7,8); $whole->add_edge(7,9);
$whole->add_edge(8,9);

ok($whole, MyGraphs::Graph_from_graph6_str('>>graph6<<Ir[gGOzCW'),
   'whole, in drawing labelling');
ok (!! MyGraphs::Graph_is_isomorphic($whole,
                                     MyGraphs::Graph_from_graph6_filename
                                     (MyGraphs::hog_num_to_filename(31137))),
    1,
    'whole, in HOG');

#------------------------------------------------------------------------------
# with 8,9 delete per Erdos and Renyi
# https://hog.grinvin.org/ViewGraphInfo.action?id=31139

my $del = $whole->copy;
$del->delete_edge(8,9);
ok (! MyGraphs::Graph_is_isomorphic($whole, $del), 1);

ok($del, MyGraphs::Graph_from_graph6_str('>>graph6<<Ir[gGOzCO'),
   'del, in drawing labelling');
ok (!! MyGraphs::Graph_is_isomorphic($del,
                                     MyGraphs::Graph_from_graph6_filename
                                     (MyGraphs::hog_num_to_filename(31139))),
    1,
    'del, in HOG');


#------------------------------------------------------------------------------
# with 4,5 del, which is other possible delete
# https://hog.grinvin.org/ViewGraphInfo.action?id=31141

my $del45 = $whole->copy;
$del45->delete_edge(4,5);

ok($del45, MyGraphs::Graph_from_graph6_str('>>graph6<<Ir[_GOzCW'),
   'del45, in drawing labelling');
ok (!! MyGraphs::Graph_is_isomorphic($del45,
                                     MyGraphs::Graph_from_graph6_filename
                                     (MyGraphs::hog_num_to_filename(31141)),
                                     'del45, in HOG'),
    1);;

ok (! MyGraphs::Graph_is_isomorphic($whole, $del45), 1);
ok (! MyGraphs::Graph_is_isomorphic($del, $del45), 1);

ok($del45->degree(2), 5);
ok($del45->degree(3), 5);
ok($del45->degree(4), 5);
foreach my $v ($del45->neighbours(2)) {
  ok ($del45->degree($v) != 3,  1);
}

#------------------------------------------------------------------------------
# with 3,5 add
# https://hog.grinvin.org/ViewGraphInfo.action?id=31143

my $add = $whole->copy;
ok (! $add->has_edge(3,5), 1);
$add->add_edge(3,5);

ok($add, MyGraphs::Graph_from_graph6_str('>>graph6<<Ir[wGOzCW'),
   'add, in drawing labelling');
ok (!! MyGraphs::Graph_is_isomorphic($add,
                                     MyGraphs::Graph_from_graph6_filename
                                     (MyGraphs::hog_num_to_filename(31143)),
                                     'add, in HOG'),
    1);;

ok (! MyGraphs::Graph_is_isomorphic($whole, $add), 1);
ok (! MyGraphs::Graph_is_isomorphic($del, $add), 1);
ok (! MyGraphs::Graph_is_isomorphic($del45, $add), 1);

#------------------------------------------------------------------------------
exit 0;
