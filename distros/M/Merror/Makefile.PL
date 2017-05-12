use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
		NAME 					=> 'Merror',
		VERSION_FROM 	=> 'lib/Merror.pm', # finds $VERSION
		PREREQ_FATAL		=> 1,
		PREREQ_PM			=> {
				strict => 0,
				warnings => 0,
				Test::More => 0.94,
		}, # e.g., Module::Name => 1.1
		($] >= 5.005 ?     ## Add these new keywords supported since 5.005
				(
						ABSTRACT	      => 'Object oriented errorhandling with a stacktrace option',
						AUTHOR         => 'Markus Mazurczak <coding@markus-mazurczak.de>'
				) : ()
		),
);
