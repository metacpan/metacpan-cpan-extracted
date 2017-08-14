#!/usr/bin/perl -w

# Copyright 2015, 2016, 2017 Kevin Ryde
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

use Graph::Maker::Kneser;

use lib
  'devel/lib';
use MyGraphs;

plan tests => 1;


#------------------------------------------------------------------------------
# Kneser 5,2 is Petersen
{
  require Graph::Maker::Petersen;
  my $petersen = Graph::Maker->new('Petersen', undirected=>1);
  my $kneser = Graph::Maker->new('Kneser', N=>5, K=>2, undirected=>1);
  ok (MyGraphs::Graph_is_isomorphic($petersen, $kneser), 1);
}

#------------------------------------------------------------------------------
exit 0;
