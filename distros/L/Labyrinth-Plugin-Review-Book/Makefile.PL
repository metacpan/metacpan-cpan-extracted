#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::Plugin::Review::Book',
    VERSION_FROM        => 'lib/Labyrinth/Plugin/Review/Book.pm',
    ABSTRACT            => 'Book Reviews plugin for the Labyrinth framework',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Clone'                                 => '0',
        'Labyrinth'                             => '5.29',
        'Labyrinth::Plugin::Review'             => '0',
        'WWW::Scraper::ISBN'                    => '1.03',

        # build/test prereqs
        'Test::More'                            => '0.70',
        'IO::File'                              => '0'

    }
);
