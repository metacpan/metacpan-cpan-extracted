#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'KiokuX::User',
    VERSION_FROM => 'lib/KiokuX/User.pm',
    INSTALLDIRS  => 'site',
    SIGN         => 1,
    PL_FILES     => { },
    PREREQ_PM    => {
        'Test::use::ok' => 0,
        'namespace::clean' => 0,
        'Moose' => 0.63,
        'MooseX::Role::Parameterized' => 0,
        'KiokuDB' => 0.09,
        'Sub::Exporter' => 0,
        'MooseX::Types::Authen::Passphrase' => 0,
    },
);

# ex: set sw=4 et:
