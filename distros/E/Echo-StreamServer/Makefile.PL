use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Echo::StreamServer',
    VERSION_FROM      => 'lib/Echo/StreamServer/Core.pm', # finds $VERSION
    EXE_FILES         => [ 'eql_shell.pl' ], # cmd line scripts
    PREREQ_PM         => {
				"Data::Dumper" => 2.121,
				"HTTP::Headers" => 1.64,
				"HTTP::Request" => 1.40,
				"JSON" => 2.17,
				"LWP::UserAgent" => 2.033,
				"Storable" => 2.15,
				"Term::ReadLine" => 1.02,
				"URI" => 1.35,
				"URI::Escape" => 3.28,
			}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => "This is a PERL version of the Echo StreamServer API.",
       AUTHOR         => 'Andrew Droffner <adroffne@advance.net>') : ()),
);
