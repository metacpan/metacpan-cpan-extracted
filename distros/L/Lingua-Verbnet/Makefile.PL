#!/usr/bin/perl
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME            => 'Lingua::Verbnet',
	VERSION_FROM    => 'lib/Lingua/Verbnet.pm',
	EXE_FILES	=> [ 'verbstat' ],
	PREREQ_PM => {
		'XML::Parser' => 0,
		'Pod::Usage' => 0,
	},
);
