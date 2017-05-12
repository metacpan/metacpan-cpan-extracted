#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'GD::Chart::Radial',
    VERSION_FROM        => 'lib/GD/Chart/Radial.pm',
    ABSTRACT            => 'Plot and output Radial or Radar charts using the GD library',
    NO_META             => 1,
    PREREQ_PM => {

        # for module
        'GD'            => '2.00',

        # for testing
        'IO::File'      => 0,
        'Test::More'    => 0.70

    },
);
