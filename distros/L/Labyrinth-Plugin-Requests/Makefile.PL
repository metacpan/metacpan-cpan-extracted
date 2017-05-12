#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::Plugin::Requests',
    VERSION_FROM        => 'lib/Labyrinth/Plugin/Requests.pm',
    ABSTRACT            => 'Requests handler for the Labyrinth framework',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Labyrinth'                 => '5.32',

        # build/test prereqs
        'IO::File'                  => '0',
        'Labyrinth::Test::Harness'  => '1.02',
        'Test::More'                => '0.70'

    }
);
