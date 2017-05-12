#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lingua::EN::NameCase',
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    VERSION_FROM        => 'lib/Lingua/EN/NameCase.pm',
    ABSTRACT            => "Correctly case a person's name from UPERCASE or lowcase",
    LICENSE             => 'artistic_2',
    PL_FILES            => {},
    NO_META             => 1,
    PREREQ_PM => {

        'Carp'                  => '0',
        'Exporter'              => '0',
        
        # build/test prereqs
        'IO::File'              => '0',
        'Test::More'            => '0.70'

    },
    'LIBS'              => [''],   # e.g., '-lm'
    'DEFINE'            => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'               => '',     # e.g., '-I/usr/include/other'
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
