#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012, 2014, 2015, 2019 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.

# aiming for 5.005 and up same as Finance::Quote itself
use 5.005;
use strict;
use ExtUtils::MakeMaker;

my %PREREQ_PM = (
                 'Finance::Quote' => 1.15,

                 # Finance::Quote depends on this already actually
                 'HTML::TableExtract' => 0,

                 # version 5.814 for HTTP::Request::accept_decodable()
                 'LWP' => '5.814',
                 # parts of LWP, but used explicitly, so name them
                 'HTTP::Request'  => 0,
                 'HTTP::Response' => 0,
                 'URI::Escape'    => 0,

                 'Scalar::Util' => 0,
                );
my %TEST_REQUIRES = (
                     'Test::More'   => 0,
                    );
unless (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
  # past ExtUtils::MakeMaker without separate TEST_REQUIRES
  %PREREQ_PM = (%PREREQ_PM, %TEST_REQUIRES);
}

WriteMakefile
  (NAME             => 'Finance::Quote::Grab',
   ABSTRACT         => 'Fetch stock quotes from a grab bag of sources.',
   VERSION_FROM     => 'lib/Finance/Quote/MLC.pm',
   AUTHOR           => 'Kevin Ryde <user42_kevin@yahoo.com.au>',
   LICENSE          => 'gpl_3',
   SIGN             => 1,
   MIN_PERL_VERSION => '5.005',
   PREREQ_PM        => \%PREREQ_PM,
   TEST_REQUIRES    => \%TEST_REQUIRES,

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/finance-quote-grab/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'] },

     # Finance::Quote::Grab gets the dist name, no actual module of that name
     provides =>
     { 'Finance::Quote::Grab'  => { file => 'META.yml',
                                    version => 15,
                                  },
       'Finance::Quote::Ghana' => { file => 'Finance/Quote/Ghana.pm',
                                    version => 15,
                                  },
       'Finance::Quote::MGEX'  => { file => 'lib/Finance/Quote/MGEX.pm',
                                    version => 15,
                                  },
       'Finance::Quote::MLC'   => { file => 'lib/Finance/Quote/MLC.pm',
                                    version => 15,
                                  },
       'Finance::Quote::RBA'   => { file => 'lib/Finance/Quote/RBA.pm',
                                    version => 15,
                                  },
     },

     prereqs =>
     { test =>
       { suggests =>
         { 'Pod::Parser' => 0,
         },
       },
     },
   },
  );
