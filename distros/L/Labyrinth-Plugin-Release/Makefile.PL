#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::Plugin::Release',
    VERSION_FROM        => 'lib/Labyrinth/Plugin/Release.pm',
    ABSTRACT            => 'Release plugin for the Labyrinth framework',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Clone'                                 => '0',
        'Labyrinth'                             => '5.20',
        'Labyrinth::Plugin::Core'               => '5.15',
        'Labyrinth::Plugin::Articles::Lyrics'   => '1.00',
        'Labyrinth::Plugin::Articles::Profiles' => '1.00',
        'Labyrinth::Plugin::MP3s'               => '1.00',

        # build/test prereqs
        'IO::File'                              => '0',
        'Test::More'                            => '0.70'

    }
);
