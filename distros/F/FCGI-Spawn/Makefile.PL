# -*- perl -*-
# Copyright (c) 2010, Peter Vereshagin
# This library is free software released "AS IS WITH ALL FAULTS"
# and WITHOUT ANY WARRANTIES under the terms of the GNU Lesser
# General Public License, Version 2.1, a copy of which can be
# found in the "COPYING" file of this distribution.

require 5.004;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'FCGI::Spawn',
    VERSION_FROM => 'lib/FCGI/Spawn.pm',    # finds $VERSION
    DISTNAME     => 'FCGI-Spawn',
    (   $] >= 5.005
        ? ( ABSTRACT =>
                'FastCGI server for CGI-like applications multiprocessing',
            AUTHOR => 'Peter V. Vereshagin (peter@vereshagin.org)'
            )
        : (),
    ),
    dist         => { COMPRESS => 'gzip', SUFFIX => 'gz', },
    PREREQ_PRINT => 1,
    EXE_FILES    => [ 'bin/fcgi_spawn', ],
    PREREQ_PM    => {
        'FCGI::ProcManager' => 0,
        'Test::Strict'      => 0,
        'Test::Most'        => 0,
        'Const::Fast'       => 0,
        'FCGI'              => 0,
        'CGI::Fast'         => 0,
    },
);
