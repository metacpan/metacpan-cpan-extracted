use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'KelpX::Hooks',
	VERSION_FROM => 'lib/KelpX/Hooks.pm',
	MIN_PERL_VERSION => '5.010',

	PREREQ_PM => {
	 	'Kelp' => '0',
	},

	META_MERGE => {
		resources => {
			license => 'https://dev.perl.org/licenses',
			homepage => 'https://brtastic.xyz/project/kelp',
			bugtracker => 'https://github.com/brtastic/perl-kelpx-hooks/issues',
			repository => 'https://github.com/brtastic/perl-kelpx-hooks',
		},
	},

	ABSTRACT_FROM => 'lib/KelpX/Hooks.pm',
	AUTHOR => 'Bartosz Jarzyna <brtastic.dev@gmail.com>',
	LICENSE => 'perl',
);
