#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Method::Specialize',
	VERSION_FROM => 'lib/Method/Specialize.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
        'Class::MethodCache' => 0.02,
        'Sub::Name' => 0.04,
        'namespace::clean' => 0.08,
	},
);

