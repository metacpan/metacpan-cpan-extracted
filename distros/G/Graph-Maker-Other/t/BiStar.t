#!/usr/bin/perl -w

# Copyright 2017 Kevin Ryde
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

# uncomment this to run the ### lines
# use Smart::Comments;

plan tests => 20;

require Graph::Maker::BiStar;


#------------------------------------------------------------------------------
{
  my $want_version = 6;
  ok ($Graph::Maker::BiStar::VERSION, $want_version, 'VERSION variable');
  ok (Graph::Maker::BiStar->VERSION,  $want_version, 'VERSION class method');
  ok (eval { Graph::Maker::BiStar->VERSION($want_version); 1 }, 1,
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Graph::Maker::BiStar->VERSION($check_version); 1 }, 1,
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# N=0 or M=0 same as Star
# same vertex numbers, so stringize to same

require Graph::Maker::Star;
foreach my $N (2 .. 5) {
  foreach my $undirected (0, 1) {
    my $star = Graph::Maker->new('star',
                                 N => $N,
                                 undirected => $undirected);
    my $bistar = Graph::Maker->new('bi_star',
                                   N => $N, M => 0,
                                   undirected => $undirected);
    ok ("$bistar","$star");
  }
}
foreach my $N (2 .. 5) {
  foreach my $undirected (0, 1) {
    my $star = Graph::Maker->new('star',
                                 N => $N,
                                 undirected => $undirected);
    my $bistar = Graph::Maker->new('bi_star',
                                   N => 0, M => $N,
                                   undirected => $undirected);
    ok ("$bistar","$star");
  }
}

#------------------------------------------------------------------------------
exit 0;
