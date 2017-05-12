use strict;
use ExtUtils::MakeMaker;

&WriteMakefile(

	ABSTRACT	 => 'Extract n-grams from texts and list them according to frequency and/or T-Score',
	AUTHOR		 => 'Eric Lease Morgan',
	clean        => { FILES => 'Lingua-EN-Ngram-* MANIFEST.bak .DS_Store' },
	depend		 => { Makefile => '$(VERSION_FROM)' },
	dist 		 => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
	NAME		 => 'Lingua::EN::Ngram',
	PREREQ_PM	 => { 'Test::More' => 0, 'Test::Exception' => 0 },
	VERSION_FROM => 'lib/Lingua/EN/Ngram.pm',

);

