#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::Plugin::Event',
    VERSION_FROM        => 'lib/Labyrinth/Plugin/Event.pm',
    ABSTRACT            => 'Event plugin for the Labyrinth framework',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Labyrinth'                             => '5.17',
        'Labyrinth::Plugin::Articles::Sections' => '5.06',
        'Labyrinth::Test::Harness'              => '1.07',
        'Clone'                                 => '0',
        'Time::Local'                           => '0',

        # build/test prereqs
        'DateTime'                              => '0',
        'IO::File'                              => '0',
        'Test::More'                            => '0.70'

    }
);
