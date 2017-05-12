#!/usr/bin/perl -w

use strict;
use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(
    VERSION_FROM   => 'lib/Lustre/LFS.pm',
    NAME           => 'Lustre::LFS',
    PREREQ_PM      => { 
                         'IO::File' => 0,
                         'IO::Dir'  => 0,
                      },
    ABSTRACT_FROM  => 'lib/Lustre/LFS.pm',
    AUTHOR         => 'Adrian Ulrich <adrian@id.ethz.ch>',
);

