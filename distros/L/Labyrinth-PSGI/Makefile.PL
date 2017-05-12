#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::PSGI',
    VERSION_FROM        => 'lib/Labyrinth/PSGI.pm',
    ABSTRACT	        => 'PSGI handler for Labyrinth',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'CGI::PSGI'             => 0,
        'CGI::Cookie'           => 0,
        'IO::File'              => 0,
        'Labyrinth'             => 0,
        'Labyrinth::Variables'  => 0,

        # build/test prereqs
        'Test::More'            => '0.70',
    }
);
