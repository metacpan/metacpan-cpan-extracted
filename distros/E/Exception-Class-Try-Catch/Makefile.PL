#!/usr/bin/perl
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME             => 'Exception::Class::Try::Catch',
	VERSION_FROM     => 'lib/Exception/Class/Try/Catch.pm',
	ABSTRACT_FROM    => 'lib/Exception/Class/Try/Catch.pm',
	AUTHOR           => 'Pali <pali@cpan.org>',
	LICENSE          => 'perl_5',
	MIN_PERL_VERSION => '5.6.0',

	PREREQ_PM => {
		'strict'                 => '0',
		'warnings'               => '0',
		'Carp'                   => '0',
		'Exception::Class::Base' => '0',
		'Exporter'               => '5.57',
		'Scalar::Util'           => '0',
		'Try::Catch'             => '0',
	},
	TEST_REQUIRES => {
		'Test::More'             => '0',
	},
	eval { ExtUtils::MakeMaker->VERSION('6.68') } ? (
	META_MERGE => {
		'meta-spec' => {
			version => 2,
		},
		'resources' => {
			bugtracker => {
				web  => 'https://github.com/pali/Exception-Class-Try-Catch/issues',
			},
			repository => {
				url  => 'git://github.com/pali/Exception-Class-Try-Catch.git',
				web  => 'https://github.com/pali/Exception-Class-Try-Catch',
				type => 'git',
			},
		},
	},
	) : (),
);
