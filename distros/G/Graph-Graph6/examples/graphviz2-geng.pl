#!/usr/bin/perl -w

# Copyright 2015, 2017, 2018 Kevin Ryde
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


# Usage: perl graphviz2-geng.pl
#
# Run the Nauty tools "geng" program (or which is "nauty-geng" on Debian) to
# generate some degree-3 "cubic" graphs and display them successively using
# GraphViz2.  There are 5 cubic graphs of 8 vertices.
#
# The graphviz "x11" driver opens an X window to display the graph.  Press
# "q" to quit or close the window to go to the next.  This (and perhaps the
# gtk driver if you have that compiled in) might be the only native
# interactive viewers.  Without them the code could be changed to an output
# file or files and run a separate viewer.
#

use strict;
use File::Spec;
use IPC::Run;
use GraphViz2;
use GraphViz2::Parse::Graph6;

my $geng_program = 'nauty-geng';     # Debian
unless (IPC::Run::run([$geng_program, '--help'],
                      '<', File::Spec->devnull,
                      '>', File::Spec->devnull, '2>&1')) {
  $geng_program = 'geng';     # native
}

my @command = ($geng_program,
               '-c',         # connected graphs
               '-d3','-D3',  # all vertices degree=3
               8,            # number of vertices
              );
print join(' ',@command),"\n";

# open OUT as a pipe filehandle to read the output of "geng"
IPC::Run::start(\@command, '>pipe', \*OUT);

my $parse = GraphViz2::Parse::Graph6->new;
for (;;) {
  my $graphviz2 = GraphViz2->new
    (global => { driver => 'neato',   # drawing by "neato" program
               },
     graph  => { overlap => 'false',  # avoid overlaps by Voroni
                 splines => 'true',   # bend edges
                 start   => 0,        # no randomization
               },
     node   => { shape   => 'circle',
               },
    );
  $parse->graph($graphviz2);
  $parse->create(fh => \*OUT)
    or last;
  $graphviz2->run(format => 'x11');
}

print "bye\n";
exit 0;
