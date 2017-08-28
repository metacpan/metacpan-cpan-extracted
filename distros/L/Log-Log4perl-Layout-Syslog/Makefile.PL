use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use File::Spec;

WriteMakefile(
    NAME		=> 'Log::Log4perl::Layout::Syslog',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/Log/Log4perl/Layout/Syslog.pm',
    ABSTRACT_FROM       => 'lib/Log/Log4perl/Layout/Syslog.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES	=> {},
    TEST_REQUIRES => {
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
    },
    # PREREQ_PM => {
	# 'Log::Log4perl::Layout' => 0,
	# 'Net::Address::IP::Local' => 0,
    # },
    dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean		=> { FILES => 'Log-Log4perl-Layout-Syslog-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/Log-Log4perl-Layout-Syslog.git',
			web => 'https://github.com/nigelhorne/Log-Log4perl-Layout-Syslog',
    		},
		bugtracker => {
			web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Log4perl-Layout-Syslog',
			mailto => 'bug-Log-Log4perl-Layout-Syslog@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
