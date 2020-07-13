use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> 'Locale::CA',
	AUTHOR  => q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM	=> 'lib/Locale/CA.pm',
	ABSTRACT_FROM   => 'lib/Locale/CA.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
	  ? ('LICENSE'=> 'GPL')
	  : ()),
	PL_FILES	=> {},
	BUILD_REQUIRES => {
	}, TEST_REQUIRES => {
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		# 'Test::Kwalitee' => 0,
	}, PREREQ_PM => {
		'Data::Section::Simple' => 0,
	},
	dist				=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean	   => { FILES => 'Locale-CA-*' },
	META_MERGE		=> {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Locale-CA.git',
				web => 'https://github.com/nigelhorne/Locale-CA-Info',
			},
		},
	},
	MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
