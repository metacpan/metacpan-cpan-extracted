#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Devel::Platform::Info',
    VERSION_FROM        => 'lib/Devel/Platform/Info.pm',
    ABSTRACT            => 'Unified framework for obtaining common platform metadata',
    NO_META             => 1,
    PREREQ_PM           => {

        # build/test prereqs
        'Test::More'                    => '0.70',
        'IO::File'                      => '0'

    }
);
