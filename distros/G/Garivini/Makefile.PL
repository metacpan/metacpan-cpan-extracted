#!/usr/bin/perl
#
#   Perl Makefile for Garivini
#
#   Invoke with 'perl Makefile.PL'
#

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Garivini',
    VERSION_FROM  => 'lib/Garivini.pm',
    AUTHOR        => 'Dormando <dormando@rydia.net>',
    ABSTRACT_FROM => 'lib/Garivini.pm',

    PREREQ_PM     => {
        'DBI'             => 0,
        'Test::More'      => 0,
        'Gearman::Client' => 0,
        'Gearman::Worker' => 0,
        'JSON'            => 0,
    },
);
