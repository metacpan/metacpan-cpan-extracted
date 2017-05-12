use strict;
use ExtUtils::MakeMaker;

&WriteMakefile(

	ABSTRACT	 => 'Keyword-in-context (KWIC) search interface',
	AUTHOR		 => 'Eric Lease Morgan',
	clean        => { FILES => 'Lingua-Concordance-* MANIFEST.bak .DS_Store' },
	depend		 => { Makefile => '$(VERSION_FROM)' },
	dist 		 => { COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
	NAME		 => 'Lingua::Concordance',
	PREREQ_PM	 => { 'Test::More' => 0, 'Math::Round' => 0 },
	VERSION_FROM => 'lib/Lingua/Concordance.pm',

);

