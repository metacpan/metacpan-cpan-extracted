use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'IO::Dir::Recursive',
    VERSION_FROM      => 'lib/IO/Dir/Recursive.pm', # finds $VERSION
    PREREQ_PM         => {
	   'IO::Dir'      => 0,
	   'IO::All'      => 0
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IO/Dir/Recursive.pm', # retrieve abstract from module
       AUTHOR         => 'Florian Ragwitz <flora@cpan.org>') : ()),
);
