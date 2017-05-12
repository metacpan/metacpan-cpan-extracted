#!/usr/bin/perl

use ExtUtils::MakeMaker;

%opts = (
	 'NAME'		=> 'Makerelease',
	 'PREREQ_PM'    => { XML::Simple => 0 },
	 'VERSION_FROM'  => 'Makerelease.pm',
	 'EXE_FILES' => [qw(makerelease)],
	);

WriteMakefile(%opts);
