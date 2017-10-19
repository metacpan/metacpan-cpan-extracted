use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES

WriteMakefile(
    NAME		=> 'Geo::Coder::Free',
    AUTHOR		=> q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM	=> 'lib/Geo/Coder/Free.pm',
    ABSTRACT_FROM       => 'lib/Geo/Coder/Free.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    BUILD_REQUIRES => {	# For bin/createdatabase
    	'App::csv2sqlite' => 0,
	'File::Copy' => 0,
    },
    TEST_REQUIRES => {
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	'Test::Number::Delta' => 0,
	'Test::Carp' => 0,
    },
    PREREQ_PM => {
	'DBI' => 0,
	'File::pfopen' => '0.02',
	'DBD::CSV' => 0,
	'Text::xSV::Slurp' => 0,
	'Gzip::Faster' => 0,
	'File::Temp' => 0,
	'Module::Info' => 0,
	'File::Spec' => 0,
	'Error::Simple' => 0,
    },
    dist		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean		=> { FILES => 'Geo-Coder-Free-*' },
    META_MERGE		=> {
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/Geo-Coder-Free.git',
			web => 'https://github.com/nigelhorne/Geo-Coder-Free',
    		},
		bugtracker => {
			web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Free',
			mailto => 'bug-Geo-Coder-Free@rt.cpan.org'
		}
	},
    },
    # PPM_INSTALL_EXEC	=> 'bash',
    # PPM_INSTALL_SCRIPT	=> 'bin/createdatabase',
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
