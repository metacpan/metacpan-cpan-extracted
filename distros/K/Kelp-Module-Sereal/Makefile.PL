use 5.010000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Kelp::Module::Sereal',
	VERSION_FROM => 'lib/Kelp/Module/Sereal.pm',
	MIN_PERL_VERSION => '5.010',

	TEST_REQUIRES => {
	},

	PREREQ_PM => {
		'Kelp' => '1',
		'Sereal' => 0,
	},

	META_MERGE => {
		resources => {
			license => 'https://dev.perl.org/licenses',
			homepage => 'https://brtastic.xyz/project/kelp',
			bugtracker => 'https://github.com/brtastic/perl-kelp-module-sereal/issues',
			repository => 'https://github.com/brtastic/perl-kelp-module-sereal',
		},
	},

	ABSTRACT_FROM => 'lib/Kelp/Module/Sereal.pm',
	AUTHOR => 'Bartosz Jarzyna <brtastic.dev@gmail.com>',
	LICENSE => 'perl',
);
