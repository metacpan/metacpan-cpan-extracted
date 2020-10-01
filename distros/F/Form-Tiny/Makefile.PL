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
		"Moo" => "0",
		"Type::Tiny" => "1.004000",
		"namespace::clean" => "0",
	},

	META_MERGE => {
		resources => {
			license => 'https://dev.perl.org/licenses',
			homepage => 'https://metacpan.org/release/Form-Tiny',
			bugtracker => 'https://github.com/brtastic/perl-form-tiny/issues',
			repository => 'https://github.com/brtastic/perl-form-tiny',
		},
	},

	ABSTRACT_FROM => 'lib/Form/Tiny.pm',
	AUTHOR => 'Bartosz Jarzyna <brtastic@gmail.com>',
	LICENSE => 'perl',
);
