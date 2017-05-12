use 5.005000;
use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
	NAME              => 'JCONF::Writer',
	LICENSE           => 'perl',
	VERSION_FROM      => 'lib/JCONF/Writer.pm',
	PREREQ_PM         => { parent => 0 },
	BUILD_REQUIRES    => {
		'Test::More' => 0.88
	},
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => 6.52,
	},
	META_MERGE        => { 
		resources => {repository => 'https://github.com/olegwtf/p5-JCONF-Writer'},
	},
	($] >= 5.005 ?
	(ABSTRACT_FROM  => 'lib/JCONF/Writer.pm',
	AUTHOR         => 'Oleg G <oleg@cpan.org>') : ()),
);
