use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Deco',
    VERSION_FROM      => 'lib/Deco.pm', # finds $VERSION
    PREREQ_PM         => {
		Config::General   => 0,
		GD::Graph         => 0,
		Test::Exception   => 0,
		Test::More        => 0,
		POSIX	          => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Deco.pm', # retrieve abstract from module
       AUTHOR         => 'Jaap Voets <narked@xperience-automatisering.nl>') : ()),
    EXE_FILES  => [
        'bin/diveplot.pl',
		   ],
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);

