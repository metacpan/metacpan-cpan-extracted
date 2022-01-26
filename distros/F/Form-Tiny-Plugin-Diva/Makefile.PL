use 5.010001;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'Form::Tiny::Plugin::Diva',
	VERSION_FROM => 'lib/Form/Tiny/Plugin/Diva.pm',
	MIN_PERL_VERSION => '5.010001',

	PREREQ_PM => {
		"Moo" => "2.000000",
		"Form::Tiny" => "2.04",
		"Form::Diva" => 0,
	},

	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			license => 'https://dev.perl.org/licenses',
			bugtracker => {
				web => 'https://github.com/bbrtj/perl-form-tiny-plugin-diva/issues',
			},
			repository => {
				type => 'git',
				url => 'https://github.com/bbrtj/perl-form-tiny-plugin-diva.git',
				web => 'https://github.com/bbrtj/perl-form-tiny-plugin-diva',
			},
		},
	},

	ABSTRACT_FROM => 'lib/Form/Tiny/Plugin/Diva.pm',
	AUTHOR => 'Bartosz Jarzyna <bbrtj.pro@gmail.com>',
	LICENSE => 'perl',
);
