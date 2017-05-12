#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

# This file is part of LWP-Protocol-rsync.
#
# LWP-Protocol-rsync is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# LWP-Protocol-rsync is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with LWP-Protocol-rsync.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'LWP-Protocol-rsync',
   ABSTRACT     => 'LWP back-end for rsync:// by running the rsync program.',
   VERSION_FROM => 'lib/LWP/Protocol/rsync.pm',
   PREREQ_PM    => {
                    'LWP::Protocol' => 0,
                    'LWP::MediaTypes' => 0,
                    'File::Spec' => 0,
                    'File::Temp' => 0,
                    'HTTP::Date' => 0,
                    'HTTP::Response' => 0,
                    'HTTP::Status' => 0,
                    'IPC::Run' => 0,
                    'URI::Escape' => 0,

                    # only for testing
                    'Test' => 0,
                   },
   AUTHOR       => 'Kevin Ryde <user42@zip.com.au>',
   LICENSE      => 'gpl_3',
   SIGN         => 1,
   MIN_PERL_VERSION => '5.005',

   META_MERGE =>
   { resources =>
     { homepage => 'http://user42.tuxfamily.org/lwp-protocol-rsync/index.html',
       license  => 'http://www.gnu.org/licenses/gpl.html',
     },
     no_index => { directory=>['devel','xt'] },

     optional_features =>
     { maximum_tests =>
       { description => 'Have "make test" do as much as possible.',
         requires => { 'LWP::UserAgent' => 0,
                     },
       },
     },
   },
  );
