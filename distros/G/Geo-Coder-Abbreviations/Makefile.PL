use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		 => 'Geo::Coder::Abbreviations',
	AUTHOR => q{Nigel Horne <njh@bandsman.co.uk>},
	VERSION_FROM => 'lib/Geo/Coder/Abbreviations.pm',
	ABSTRACT_FROM => 'lib/Geo/Coder/Abbreviations.pm',
	((defined($ExtUtils::MakeMaker::VERSION) &&
	 ($ExtUtils::MakeMaker::VERSION >= 6.3002))
		? ('LICENSE'=> 'GPL')
		: ()),
	PL_FILES => {},
	BUILD_REQUIRES => {
	}, TEST_REQUIRES => {
		'Test::Most' => 0,
		'Test::NoWarnings' => 0,
		# 'Test::Kwalitee' => 0,
	}, PREREQ_PM => {
		'JSON' => 0,
		'LWP::Simple' => 0,
	},
	dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Geo-Coder-Abbreviations-*' },
	META_MERGE  => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url => 'git://github.com/nigelhorne/Geo-Coder-Abbreviations.git',
				web => 'https://github.com/nigelhorne/Geo-Coder-Abbreviations',
			},
		},
	},
	MIN_PERL_VERSION => '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
