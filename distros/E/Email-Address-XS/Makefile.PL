#!/usr/bin/perl
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME             => 'Email::Address::XS',
	VERSION_FROM     => 'lib/Email/Address/XS.pm',
	ABSTRACT_FROM    => 'lib/Email/Address/XS.pm',
	AUTHOR           => 'Pali <pali@cpan.org>',
	H                => [ 'dovecot-parser.h' ],
	C                => [ 'dovecot-parser.c', 'Email-Address-XS.c' ],
	XS               => { 'Email-Address-XS.xs' => 'Email-Address-XS.c' },
	OBJECT           => '$(O_FILES)',
	NORECURS         => 1,
	LICENSE          => 'perl_5',
	MIN_PERL_VERSION => '5.6.0',

	PREREQ_PM => {
		'base'       => '0',
		'overload'   => '0',
		'strict'     => '0',
		'warnings'   => '0',
		'Carp'       => '0',
		'Exporter'   => '0',
		'XSLoader'   => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	eval { ExtUtils::MakeMaker->VERSION('6.68') } ? (
	META_MERGE => {
		'meta-spec' => {
			version => 2,
		},
		'resources' => {
			bugtracker => {
				web  => 'https://github.com/pali/Email-Address-XS/issues',
			},
			repository => {
				url  => 'git://github.com/pali/Email-Address-XS.git',
				web  => 'https://github.com/pali/Email-Address-XS',
				type => 'git',
			},
		},
	},
	) : (),
);
