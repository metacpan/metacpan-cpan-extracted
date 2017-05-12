#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::Plugin::Articles::Diary',
    VERSION_FROM        => 'lib/Labyrinth/Plugin/Articles/Diary.pm',
    ABSTRACT            => 'Diary plugin for the Labyrinth framework',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Labyrinth'                 => '5.27',
        'Labyrinth::Plugin::Core'   => '5.17',
        'Clone'                     => 0,
        'Time::Local'               => 0,

        # build/test prereqs
        'Labyrinth::Test::Harness'  => '1.03',
        'Test::More'                => '0.70',
        'IO::File'                  => '0'

    }
);
