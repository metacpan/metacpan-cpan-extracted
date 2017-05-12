#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::DIUtils::GD',
    VERSION_FROM        => 'lib/Labyrinth/DIUtils/GD.pm',
    ABSTRACT            => 'Digital Image utilities driver with GD for Labyrinth Framework',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'GD'                    => 0,
        'IO::File'              => 0,

        # build/test prereqs
        'File::Copy'            => 0,
        'File::Path'            => 0,
        'Test::More'            => '0.70'
    }
);
