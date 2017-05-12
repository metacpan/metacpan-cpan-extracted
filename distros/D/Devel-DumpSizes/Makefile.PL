use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'Devel::DumpSizes',
    VERSION_FROM      => 'lib/Devel/DumpSizes.pm', # finds $VERSION
    PREREQ_PM         => {
		Devel::Size => 0.64,
		PadWalker => 1.0,
		Devel::Symdump => 2.0601,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Devel/DumpSizes.pm', # retrieve abstract from module
       AUTHOR         => 'Gautam Chekuri <gautam.chekuri@gmail.com>') : ()),
);
