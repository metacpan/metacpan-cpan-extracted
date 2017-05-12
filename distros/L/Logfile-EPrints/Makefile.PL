use 5.006005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Logfile::EPrints',
    VERSION_FROM      => 'lib/Logfile/EPrints.pm', # finds $VERSION
    PREREQ_PM         => {
		Carp => 0.1,
		Geo::IP::PurePerl => 1.17,
		Date::Parse => 0.1,
		LWP::UserAgent => 0.1,
		Socket => 0.1,
		URI => 0.1,
		Text::CSV_XS => 0.1,
		SDBM_File => 0.1,
		Encode => 0.1,
#		HTTP::OAI => 3.19,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Logfile/EPrints.pm', # retrieve abstract from module
       AUTHOR         => 'Timothy D Brody <tdb01r@ecs.soton.ac.uk>') : ()),
);
