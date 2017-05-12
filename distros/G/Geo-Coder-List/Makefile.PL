use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'Geo::Coder::List',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/Geo/Coder/List.pm',
    ABSTRACT_FROM       => 'lib/Geo/Coder/List.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    BUILD_REQUIRES => {
	'Test::Most' => 0,
	'Geo::Coder::Google::V3' => 0.10,
	'Geo::Coder::OSM' => 0,
	'Test::Number::Delta' => 0,
	'LWP::Protocol::https' => 0,
	'Test::NoWarnings' => 0,
    },
    PREREQ_PM => {
    },
    dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean		=> { FILES => 'Geo::Coder::List-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/Geo-Coder-List.git',
			web => 'https://github.com/nigelhorne/Geo-Coder-List',
    		},
		bugtracker => {
			web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-List',
			mailto => 'bug-Geo-Coder-List@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
