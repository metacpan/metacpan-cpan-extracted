use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'LWP::UserAgent::Throttled',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/LWP/UserAgent/Throttled.pm',
    ABSTRACT_FROM       => 'lib/LWP/UserAgent/Throttled.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    BUILD_REQUIRES => {
	'Test::Most' => 0,
	'Test::Timer' => 0,
	'LWP::Protocol::https' => 0,
	# 'Test::Kwalitee' => 0,
    },
    PREREQ_PM => {
	'LWP::UserAgent' => 0,
	'Time::HiRes' => 0,
    },
    dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean		=> { FILES => 'LWP-UserAgent::Throttled-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/LWP-UserAgent-Throttled.git',
			web => 'https://github.com/nigelhorne/LWP-UserAgent::Throttled',
    		},
		bugtracker => {
			web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=LWP-UserAgent::Throttled',
			mailto => 'bug-LWP-UserAgent::Throttled@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
