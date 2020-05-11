#!perl
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'Hal::Cdroms',
	VERSION_FROM  => 'lib/Hal/Cdroms.pm',
	ABSTRACT_FROM => 'lib/Hal/Cdroms.pm',
	AUTHOR        => 'Pixel <pixel@rigaux.org>',
	LICENSE       => 'gpl_2', # or Artistic
	MIN_PERL_VERSION => '5.008000',
	'CONFIGURE_REQUIRES' => {
	    'ExtUtils::MakeMaker' => '6.64'
	},
	META_MERGE => {
	    'meta-spec' => { version => 2 },
	    release_status => 'stable',
	    resources => {
                repository  => {
		    type => 'git',
		    url => 'git://git.mageia.org/software/perl/perl-Hal-Cdroms/',
		    web =>  'http://gitweb.mageia.org/software/perl/perl-Hal-Cdroms/',
		},
	    },
	},
);
