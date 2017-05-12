#!/usr/bin/perl

require 5.005;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'HTML::FromANSI',
    VERSION_FROM => 'lib/HTML/FromANSI.pm',
    PREREQ_PM    => {
        'Test::More'             => '0.11',
        'Term::VT102::Boundless' => '0.03',
        'HTML::Entities'         => '0.01',
        'Test::use::ok'          => 0,
    },

    EXE_FILES => [ 'script/ansi2html' ],
);

