#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Devel::Events::Filter::Size',
	VERSION_FROM => 'lib/Devel/Events/Filter/Size.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Devel::Events'       => 0,
		'Devel::Size'         => '0.69',
		#'Devel::Size::Report' => '0.11'
	},
);

