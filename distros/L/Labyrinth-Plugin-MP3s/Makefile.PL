#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth-Plugin-MP3s',
    VERSION_FROM        => 'lib/Labyrinth/Plugin/MP3s.pm',
    ABSTRACT            => 'MP3 plugin for the Labyrinth framework',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Labyrinth'                 => '5.20',
        'Labyrinth::Plugin::Core'   => '5.13',

        # build/test prereqs
        'IO::File'                  => '0',
        'Test::More'                => '0.70'

    }
);
