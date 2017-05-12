use strict;
use ExtUtils::MakeMaker;

&WriteMakefile(

	ABSTRACT	 => 'Calculate n-word phrases (bigrams, trigrams, etc.) based on frequency and/or T-Score',
	AUTHOR		 => 'Eric Lease Morgan',
	clean        => { FILES => 'Lingua-EN-Bigram-* MANIFEST.bak' },
	depend		 => { Makefile => '$(VERSION_FROM)' },
	dist 		 => { COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
	NAME		 => 'Lingua::EN::Bigram',
	PREREQ_PM	 => { 'Test::More' => 0 },
	VERSION_FROM => 'lib/Lingua/EN/Bigram.pm',

);

