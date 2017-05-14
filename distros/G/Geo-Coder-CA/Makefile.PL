use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'Geo::Coder::CA',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/Geo/Coder/CA.pm',
    ABSTRACT_FROM       => 'lib/Geo/Coder/CA.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    BUILD_REQUIRES => {
	'Test::Most' => 0,
	'Test::Number::Delta' => 0,
    },
    PREREQ_PM => {
	'Encode' => 0,
	'JSON' => 0,
	'HTTP::Request' => 0,
	'LWP::UserAgent' => 0,
	'LWP::Protocol::https' => 0,
	'URI' => 0,
    },
    dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean		=> { FILES => 'Geo-Coder-CA-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/Geo-Coder-CA.git',
			web => 'https://github.com/nigelhorne/Geo-Coder-CA',
    		},
		bugtracker => {
			web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-CA',
			mailto => 'bug-Geo-Coder-CA@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
