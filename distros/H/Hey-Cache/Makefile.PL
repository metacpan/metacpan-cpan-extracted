use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Hey::Cache',
    VERSION_FROM      => 'lib/Hey/Cache.pm', # finds $VERSION
    PREREQ_PM         => {
			'Data::DumpXML' => "1.01",
			'Data::DumpXML::Parser' => "1.01",
			  },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Hey/Cache.pm', # retrieve abstract from module
       AUTHOR         => 'Dusty Wilson <hey-cache-module@dusty.hey.nu>') : ()),
);
