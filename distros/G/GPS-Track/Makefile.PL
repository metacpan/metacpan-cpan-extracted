use 5.018000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'GPS::Track',
	VERSION_FROM      => 'lib/GPS/Track.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
	MIN_PERL_VERSION => 5.010,
	PREREQ_PM         => {
		"Moo" => 0,
		"Geo::Distance" => 0,
		"XML::Simple" => 0,
		"XML::SAX::ExpatXS" => 0, # this may require libexpat1-dev on your system.
		"DateTime" => 0,
		"DateTime::Format::ISO8601" => 0,
		"Try::Tiny" => 0,
	}, # e.g., Module::Name => 1.1
	TEST_REQUIRES => {
		"Test::More" => 0,
		"Test::Exception" => 0,
		"Version::Compare" => 0,
		"Test::Deep" => 0,
	},
	ABSTRACT_FROM     => 'lib/GPS/Track.pm', # retrieve abstract from module
	AUTHOR            => 'Sven Eppler <cpan@sveneppler.de>',
	LICENSE           => 'perl',
	#Value must be from legacy list of licenses here
	#http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
