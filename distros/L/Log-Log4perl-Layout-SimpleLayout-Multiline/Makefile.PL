#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Log::Log4perl::Layout::SimpleLayout::Multiline',
    VERSION_FROM => 'lib/Log/Log4perl/Layout/SimpleLayout/Multiline.pm',
    INSTALLDIRS  => 'site',
    SIGN         => 1,
    PL_FILES     => { },
    PREREQ_PM    => {
        'Test::use::ok' => 0,
        'Log::Log4perl' => 0,
    },
);

