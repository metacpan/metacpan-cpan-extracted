#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Devel::ArgNames',
	VERSION_FROM => 'lib/Devel/ArgNames.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		PadWalker => 0,
		'Test::use::ok' => 0,
	},
);

