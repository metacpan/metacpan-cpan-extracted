#!/usr/bin/env perl

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Filter::Unpound',
    VERSION_FROM => 'lib/Filter/Unpound.pm',
    ABSTRACT => 'Selective uncommenting for debugging.',
    AUTHOR => 'Mark E. Shoulson <mark@shoulson.com>',
    PREREQ_PM => { 'Filter::Simple' => 0 },
    BUILD_REQUIRES => { 'Filter::Simple' => 0, 'Test::More' => 0},
    LICENSE => 'perl'
    );
