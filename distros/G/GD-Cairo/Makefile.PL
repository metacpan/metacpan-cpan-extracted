use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'GD::Cairo',
    VERSION_FROM      => 'lib/GD/Cairo.pm', # finds $VERSION
    PREREQ_PM         => {
		Test::More => 0.01,
		GD => 2.35,
		Cairo => 1.023,
	}, # e.g., Module::Name => 1.1
	'dist' => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/GD/Cairo.pm', # retrieve abstract from module
       AUTHOR         => 'Tim D Brody <tdb2@localdomain>') : ()),
);
