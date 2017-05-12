#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile(
    NAME         => 'IO::Handle::Util',
    VERSION_FROM => 'lib/IO/Handle/Util.pm',
    INSTALLDIRS  => 'site',
    SIGN         => 1,
    PL_FILES     => { },
    PREREQ_PM    => {
		'Scalar::Util' => 0,
		'Sub::Exporter' => 0,
		'asa' => 0,
		'parent' => 0,
		'IO::String' => 0,

		'Test::use::ok' => 0,
		'Test::More' => 0.88,
    },
);
