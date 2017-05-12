#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::Plugin::Wiki',
    VERSION_FROM        => 'lib/Labyrinth/Plugin/Wiki.pm',
    ABSTRACT            => 'Wiki plugin for the Labyrinth framework',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Labyrinth'             => '5.16',
        'Algorithm::Diff'       => '0',
        'VCS::Lite'             => '0',

        # build/test prereqs
        'IO::File'              => '0',
        'Test::More'            => '0.70'

    }
);
