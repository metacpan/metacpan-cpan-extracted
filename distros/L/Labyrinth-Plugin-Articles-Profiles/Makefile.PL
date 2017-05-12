#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::Plugin::Articles::Profiles',
    VERSION_FROM        => 'lib/Labyrinth/Plugin/Articles/Profiles.pm',
    ABSTRACT            => 'Profiles plugin for the Labyrinth framework',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Labyrinth'                 => '5.28',
        'Labyrinth::Plugin::Core'   => '5.18',

        # build/test prereqs
        'IO::File'                  => '0',
        'Labyrinth::Test::Harness'  => '1.05',
        'Test::More'                => '0.70'

    }
);
