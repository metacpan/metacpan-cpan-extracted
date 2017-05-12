use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Log::Agent::Driver::Apache',
    VERSION_FROM      => 'lib/Log/Agent/Driver/Apache.pm', # finds $VERSION
    PREREQ_PM         => {
		'Log::Agent' => 0.306,
		'Apache2::Log' => 2.000001
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Log/Agent/Driver/Apache.pm', # retrieve abstract from module
       AUTHOR         => 'Jamie Hoglund') : ()),
);
