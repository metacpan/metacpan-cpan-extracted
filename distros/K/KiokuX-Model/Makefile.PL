#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'KiokuX::Model',
    VERSION_FROM => 'lib/KiokuX/Model.pm',
    INSTALLDIRS  => 'site',
    SIGN         => 1,
    PL_FILES     => { },
    PREREQ_PM    => {
        'KiokuDB' => 0.24,
		'MooseX::StrictConstructor' => 0.08,
    },
);
