#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Games::Trackword',
    VERSION_FROM        => 'lib/Games/Trackword.pm',
    ABSTRACT            => 'A module to help find words on a Trackword grid',
    NO_META             => 1,

    PREREQ_PM           => {

        # build/test prereqs
        'IO::File'                          => 0,
        'Test::More'                        => '0.70'

    },
);
