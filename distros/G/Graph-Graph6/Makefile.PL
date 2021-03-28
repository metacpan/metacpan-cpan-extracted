#!/usr/bin/perl -w

# Copyright 2015, 2017, 2021 Kevin Ryde

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


# Perl 5.6 mainly for 3-arg open (safety and certainty on any filename).
#
use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %PREREQ_PM = (
                 'Carp'       => 0,
                 'Exporter'   => 0,
                 'IO::String' => 0,
                 'List::Util' => 0,
                );
my %TEST_REQUIRES = (
                     # for the t/*.t tests
                     'Test' => 0,
                    );
unless (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
  # past ExtUtils::MakeMaker without separate TEST_REQUIRES
  %PREREQ_PM = (%PREREQ_PM, %TEST_REQUIRES);
}

WriteMakefile
  (NAME             => 'Graph::Graph6',
   ABSTRACT         => 'Read and write graph6, sparse6 and digraph6.',
   VERSION_FROM     => 'lib/Graph/Graph6.pm',
   MIN_PERL_VERSION => '5.006',
   PREREQ_PM        => \%PREREQ_PM,
   TEST_REQUIRES    => \%TEST_REQUIRES,

   AUTHOR       => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,

   META_MERGE =>
   { 'meta-spec' => { version => 2 },
     resources =>
     { homepage => 'http://user42.tuxfamily.org/graph-graph6/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory => ['devel','xt'],
                   package   => [ 'Graph::Easy' ], # added to, not created
                 },

     prereqs =>
     { runtime =>
       { suggests =>
         { 'Graph::Reader'       => 0,
           'Graph::Writer'       => 0,
           'Graph::Easy::Parser' => 0,
           'GraphViz2'           => 0,
         },
       },
       test =>
       { suggests =>
         { 'Graph'               => 0,
           'Graph::Reader'       => 0,
           'Graph::Writer'       => 0,
           'Graph::Easy'         => 0,
           'Graph::Easy::Parser' => 0,
           'GraphViz2'           => 0,
           'Moo'                 => 0,
         },
       },
     },
   },
  );
