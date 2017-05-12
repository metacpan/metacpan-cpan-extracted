use 5.008004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'File::Tabular',
    VERSION_FROM      => 'lib/File/Tabular.pm', # finds $VERSION
    PREREQ_PM         => {'Hash::Type' => "1.0",
			  'Search::QueryParser' => "0.92" },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/Tabular.pm', # retrieve abstract from module
       AUTHOR         => 'Laurent Dami <laurent.dami AT etat ge ch>') : ()),
);
