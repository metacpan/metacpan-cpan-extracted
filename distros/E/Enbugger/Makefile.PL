#!perl

# COPYRIGHT AND LICENCE
#
# Copyright (C) 2007,2008 WhitePages.com, Inc. with primary
# development by Joshua ben Jore.
#
# This program is distributed WITHOUT ANY WARRANTY, including but not
# limited to the implied warranties of merchantability or fitness for
# a particular purpose.
#
# The program is free software.  You may distribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation (either version 2 or any later version)
# and the Perl Artistic License as published by O’Reilly Media, Inc.
# Please open the files named gpl-2.0.txt and Artistic for a copy of
# these licenses.

use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Enbugger',
    VERSION_FROM  => 'lib/Enbugger.pm',
    ABSTRACT_FROM => 'lib/Enbugger.pod',
    AUTHOR        => 'Josh ben Jore <jjore@cpan.org>',
    LICENSE       => 'perl',
    PREREQ_PM     => {
              'Test::More' => 0,
              'B::Utils' => '0.25',
             },
    EXE_FILES => [qw(
        bin/screen-server
        bin/screen-server-backend
        bin/tmux-server
        bin/tmux-server-backend
        bin/xterm-server
        bin/xterm-server-backend
    )],
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Enbugger-*' },
    META_MERGE => {
        no_index => {
            directory => [
                't',
            ]
        },
    },
);

## Local Variables:
## mode: cperl
## mode: auto-fill
## cperl-indent-level: 4
## End:
