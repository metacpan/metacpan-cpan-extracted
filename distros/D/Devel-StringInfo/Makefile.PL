#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Devel-StringInfo',
	VERSION_FROM => 'lib/Devel/StringInfo.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Moose' => '0.20',
		'Encode' => 0,
		'Encode::Guess' => 0,
		'Tie::IxHash' => 0,
		'Test::use::ok' => 0,
		'Sub::Exporter' => 0,
		'namespace::clean' => 0.08,
	},
);

