#!/usr/bin/perl -w

# Copyright 2016, 2017 Kevin Ryde
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

plan tests => 323;


use FindBin;
use lib "$FindBin::Bin/../devel/lib";
require Graph::Maker::Dragon;


#------------------------------------------------------------------------------
{
  my $want_version = 10;
  ok ($Graph::Maker::Dragon::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::Dragon->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::Dragon->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::Dragon->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------

{
  my $graph = Graph::Maker->new('dragon', level=>0);
  ok (scalar($graph->vertices), 2);
  ok ("$graph", "0,0-1,0");
}

{
  my $graph = Graph::Maker->new('dragon', level=>4, part=>'blob');
  ok (scalar($graph->vertices), 4);
  ok ($graph->has_vertex('-2,1')?1:0, 1);
}

#------------------------------------------------------------------------------
exit 0;
