#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Devel::Events::Generator::ClassPublisher',
	VERSION_FROM => 'lib/Devel/Events/Generator/ClassPublisher.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Devel::Events' => '0.03',
		'Class::Publisher' => 0,
		'Test::use::ok' => 0,
	},
);

