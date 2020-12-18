#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker qw(6.64);

WriteMakefile(
    NAME          => 'Math::Base85',
    VERSION_FROM  => 'lib/Math/Base85.pm',
    ABSTRACT_FROM => 'lib/Math/Base85.pm',
    AUTHOR        => [
        'Tony Monroe <tmonroe plus perl at nog dot net>',
        'Paul Cochrane <ptc@cpan.org>',
    ],
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => 5.006,
    PREREQ_PM        => {
        'constant'     => 0,
        'strict'       => 0,
        'vars'         => 0,
        'warnings'     => 0,
        'Carp'         => 0,
        'Exporter'     => 0,
        'Math::BigInt' => '0',
    },
    TEST_REQUIRES => {
        'Test'       => 0,
        'Test::More' => 0,
    },
    META_MERGE => {
        "meta-spec"    => { version => 2 },
        dynamic_config => 0,
        resources      => {
            bugtracker => {
                web => 'https://github.com/paultcochrane/Math-Base85/issues',
            },
            repository => {
                type => 'git',
                url  => 'git@github.com:paultcochrane/Math-Base85.git',
                web  => 'https://github.com/paultcochrane/Math-Base85',
            },
        },
    },
);

# vim: expandtab shiftwidth=4
