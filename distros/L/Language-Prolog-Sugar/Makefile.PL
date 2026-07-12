use strict;
use warnings;
use utf8;
use ExtUtils::MakeMaker 6.64;

WriteMakefile(
	NAME             => 'Language::Prolog::Sugar',
	VERSION_FROM     => 'Sugar.pm',
	ABSTRACT_FROM    => 'Sugar.pm',
	AUTHOR           => 'Salvador Fandiño <sfandino@yahoo.com>',
	LICENSE          => 'perl_5',
	MIN_PERL_VERSION => '5.006',

	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '6.64',
	},
	PREREQ_PM => {
		'Language::Prolog::Types' => 0,
	},
	TEST_REQUIRES => {
		'Test::More' => 0,
	},

	META_MERGE => {
		'meta-spec' => { version => 2 },
		dynamic_config => 0,
		prereqs => {
			develop => {
				requires => {
					'Test::Pod' => '1.00',
				},
			},
		},
		resources => {
			repository => {
				type => 'git',
				url  => 'https://github.com/salva/p5-Language-Prolog-Sugar.git',
				web  => 'https://github.com/salva/p5-Language-Prolog-Sugar',
			},
			bugtracker => {
				web => 'https://github.com/salva/p5-Language-Prolog-Sugar/issues',
			},
		},
	},

	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
	clean => { FILES => 'Language-Prolog-Sugar-*' },
);
