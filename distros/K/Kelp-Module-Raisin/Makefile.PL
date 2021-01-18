use 5.010000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Kelp::Module::Raisin',
	VERSION_FROM => 'lib/Kelp/Module/Raisin.pm',
	MIN_PERL_VERSION => '5.010',

	TEST_REQUIRES => {
		'Test::Exception' => 0,
	},

	PREREQ_PM => {
		'Kelp' => '1',
		'Kelp::Module::Symbiosis' => '1.10',
		'Raisin' => 0,
	},

	META_MERGE => {
		resources => {
			license => 'https://dev.perl.org/licenses',
			homepage => 'https://brtastic.xyz/project/kelp',
			bugtracker => 'https://github.com/brtastic/perl-kelp-module-raisin/issues',
			repository => 'https://github.com/brtastic/perl-kelp-module-raisin',
		},
	},

	ABSTRACT_FROM => 'lib/Kelp/Module/Raisin.pm',
	AUTHOR => 'Bartosz Jarzyna <brtastic.dev@gmail.com>',
	LICENSE => 'perl',
);
