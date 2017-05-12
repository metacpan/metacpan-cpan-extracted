#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Labyrinth::Paths',
    VERSION_FROM        => 'lib/Labyrinth/Paths.pm',
    ABSTRACT	        => 'CGI path translation for Labyrinth',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'IO::File'              => 0,
        'JSON::XS'              => 0,
        'Labyrinth'             => 0,
        'Labyrinth::Variables'  => 0,

        # build/test prereqs
        'Test::More'            => '0.70',
    }
);
