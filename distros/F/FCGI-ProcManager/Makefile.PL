# -*- perl -*-
# Copyright (c) 2000, FundsXpress Financial Network, Inc.
# This library is free software released "AS IS WITH ALL FAULTS"
# and WITHOUT ANY WARRANTIES under the terms of the GNU Lesser
# General Public License, Version 2.1, a copy of which can be
# found in the "COPYING" file of this distribution.

# $Id: Makefile.PL,v 1.2 2000/11/10 01:09:41 muaddib Exp $

require 5.004;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile
  (NAME         => 'FCGI::ProcManager',
   VERSION_FROM => 'lib/FCGI/ProcManager.pm',   # finds $VERSION
   DISTNAME     => 'FCGI-ProcManager',
   ($] >= 5.005 ?
    (ABSTRACT   => 'A perl-based FastCGI process manager',
     AUTHOR     => 'James E Jurach (muaddib@erf.net)') : ()),
   dist         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    META_MERGE => {
        resources => {
            repository  =>      'git://git.shadowcat.co.uk/catagits/FCGI-ProcManager',
        },
    },
  );
