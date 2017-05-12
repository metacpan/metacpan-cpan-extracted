#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::Demo',
    VERSION_FROM        => 'lib/Labyrinth/Demo.pm',
    ABSTRACT	        => 'Labyrinth Website Management Framework - Demo Website',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Labyrinth'                 => '5.29',
        'Labyrinth::Plugin::Core'   => '5.18',

        # build/test prereqs
        'IO::File'                  => 0,
        'Test::More'                => '0.70',
    },
);
