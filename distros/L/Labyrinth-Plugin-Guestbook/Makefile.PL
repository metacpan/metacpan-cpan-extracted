#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::Plugin::Guestbook',
    VERSION_FROM        => 'lib/Labyrinth/Plugin/Guestbook.pm',
    ABSTRACT            => 'Guestbook plugin for the Labyrinth framework',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Data::Pageset'             => '0',
        'Labyrinth'                 => '5.20',
        'Labyrinth::Plugin::Core'   => '5.15',

        # build/test prereqs
        'IO::File'                  => '0',
        'Labyrinth::Test::Harness'  => '1.08',
        'Test::More'                => '0.70'

    }
);
