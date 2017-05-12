#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Devel::Events',
	VERSION_FROM => 'lib/Devel/Events.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Moose'                    => '0.33',
		'MooseX::AttributeHelpers' => '0.03',
		'Set::Object'              => 0,
		'Sub::Uplevel'             => 0,
		'Time::HiRes'              => 0,
		'Test::use::ok'            => 0,
		'Try::Tiny'                => 0,
	},
);

