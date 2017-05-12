#!/usr/bin/perl -w

use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Locale::Handle::Pluggable',
	VERSION_FROM => 'lib/Locale/Handle/Pluggable.pm',
	INSTALLDIRS  => 'site',
	SIGN         => 1,
	PL_FILES     => { },
	PREREQ_PM    => {
		'Test::use::ok' => 0,
        'Moose' => 0,
        'DateTime' => 0,
        'MooseX::Types::VariantTable::Declare' => 0,
        'MooseX::Types::DateTime' => 0,
	},
);

