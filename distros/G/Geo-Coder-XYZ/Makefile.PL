use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'Geo::Coder::XYZ',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/Geo/Coder/XYZ.pm',
    ABSTRACT_FROM       => 'lib/Geo/Coder/XYZ.pm',
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
    clean		=> { FILES => 'Geo-Coder-XYZ-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/Geo-Coder-XYZ.git',
			web => 'https://github.com/nigelhorne/Geo-Coder-XYZ',
    		},
		bugtracker => {
			web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-XYZ',
			mailto => 'bug-Geo-Coder-XYZ@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
