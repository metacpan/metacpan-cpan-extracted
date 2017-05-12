#!/usr/bin/env perl -w
use 5.008;
use strict;
use ExtUtils::MakeMaker;

my @programs_to_install = qw(sitetear);

WriteMakefile(
	'NAME'	 => 'HTML::SiteTear',
	'VERSION_FROM' => 'lib/HTML/SiteTear.pm',
	'EXE_FILES'     => [ map {"bin/$_"} @programs_to_install ],
	'PREREQ_PM' => {
		'Test::More'   => 0,
		'HTML::Parser' => 3.40,
        'HTML::Copy' => 0,
		'Class::Accessor' => 0,
        'URI' => 0
	},
	'dist'           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },	
	'clean'          => { FILES => 'HTML-SiteTear-*' },
);
