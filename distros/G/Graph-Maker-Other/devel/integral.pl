#!/usr/bin/perl -w

# Copyright 2020 Kevin Ryde
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
use Math::BaseCnv 'cnv';

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'devel', 'lib');
use MyGraphs;
$|=1;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # Brouwer integral trees
  # n=31
  # https://hog.grinvin.org/ViewGraphInfo.action?id=34222
  # one of 3 n=31
  # Other n=31
  # (ii)  SK star of 15 arms length 2
  # Wang p68

  # A. E. Brouwer, "Small Integral Trees", Electr. J. Combin., volume 15,
  # 2008
  # http://www.win.tue.nl/~aeb/graphs/integral_trees.html
  # http://www.win.tue.nl/~aeb/preprints/small_itrees.pdf

  # ../../vpar/devel/integral-tree-try.gp
  my $graph = MyGraphs::Graph_from_graph6_str
    (':^_`aaa_efehej_lmlolq_ssss_xxxx_');
  my $f = 6.5;
  MyGraphs::Graph_set_xy_points($graph,
                                30 => [0,1],
                                '00' => [0,0],
                                '01' => [0,-1],
                                '02' => [0,-2],
                                '03' => [-1,-3],
                                '04' => [0,-3],
                                '05' => [1,-3],

                                '06' => [-3,-1],
                                '07' => [-4,-2],
                                '08' => [-4,-3],
                                '09' => [-3,-2],
                                '10' => [-3,-3],
                                '11' => [-2,-2],
                                '12' => [-2,-3],

                                '13' => [3,-1],
                                '14' => [4,-2],
                                '15' => [4,-3],
                                '16' => [3,-2],
                                '17' => [3,-3],
                                '18' => [2,-2],
                                '19' => [2,-3],

                                20 => [-($f),    -1],
                                21 => [-($f-1.5),-2],
                                22 => [-($f-.5), -2],
                                23 => [-($f+.5), -2],
                                24 => [-($f+1.5),-2],

                                25 => [$f,    -1],
                                26 => [$f-1.5,-2],
                                27 => [$f-.5, -2],
                                28 => [$f+.5, -2],
                                29 => [$f+1.5,-2],

                               );
  MyGraphs::Graph_view($graph);
  MyGraphs::hog_searches_html($graph);
  MyGraphs::hog_upload_html($graph);
  exit 0;
}
