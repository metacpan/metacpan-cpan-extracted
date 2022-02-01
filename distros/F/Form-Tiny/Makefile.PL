use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Form::Tiny',
	VERSION_FROM => 'lib/Form/Tiny.pm',
	MIN_PERL_VERSION => '5.010001',

	TEST_REQUIRES => {
		'Test::Exception' => "0",
	},

	PREREQ_PM => {
		"Moo" => "2.000000",
		"Type::Tiny" => "1.004000",
		"Import::Into" => "0",
		"namespace::clean" => "0",
		"Sub::Util" => "0",
	},

	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			license => 'https://dev.perl.org/licenses',
			homepage => 'https://bbrtj.eu/project/form-tiny',
			bugtracker => {
				web => 'https://github.com/bbrtj/perl-form-tiny/issues',
			},
			repository => {
				type => 'git',
				url => 'https://github.com/bbrtj/perl-form-tiny.git',
				web => 'https://github.com/bbrtj/perl-form-tiny',
			},
		},
	},

	test => {
		TESTS => "t/*.t t/**/*.t"
	},

	ABSTRACT_FROM => 'lib/Form/Tiny.pm',
	AUTHOR => 'Bartosz Jarzyna <bbrtj.pro@gmail.com>',
	LICENSE => 'perl',
);
