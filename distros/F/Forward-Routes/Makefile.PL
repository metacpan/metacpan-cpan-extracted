#!/usr/bin/env perl

# Copyright (C) 2013, ForwardEver

use 5.010001;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME         => 'Forward::Routes',
    VERSION_FROM => 'lib/Forward//Routes.pm',
    ABSTRACT     => 'Forward::Routes: routes for web framework builders',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                requires  => {perl => '5.010001'},
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    repository => 'https://github.com/forwardever/Forward-Routes',
                    bugtracker => 'https://github.com/forwardever/Forward-Routes/issues'
                },
                no_index => {directory => [qw/t/]}
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),
    PREREQ_PM => {
      'Carp'   => 0,
      'parent' => 0
    },
    test      => {TESTS => 't/*.t t/*/*.t'}
);

1;

