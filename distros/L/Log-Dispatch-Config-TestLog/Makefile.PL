#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Log::Dispatch::Config::TestLog',
	VERSION_FROM => 'lib/Log/Dispatch/Config/TestLog.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Path::Class' => 0,
		'Log::Dispatch::Binlog' => 0, # for test
		'Log::Dispatch::Config' => 0,
		'Sub::Override' => 0,
		'Test::Builder' => '0.96',
		'Perl::Command' => 0,
		'Test::Deep' => 0,
	},
);

