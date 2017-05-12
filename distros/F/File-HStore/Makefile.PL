use 5.004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'File::HStore',
    VERSION_FROM      => 'lib/File/HStore.pm', # finds $VERSION
    PREREQ_PM         => { 'Digest::SHA' => '0',
			   'File::Copy' => '0',
			   'Test::More' => '0',
			   'File::Path' => '0' }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/File/HStore.pm', # retrieve abstract from module
       LICENSE	      => 'perl',
       AUTHOR         => 'Alexandre Dulaunoy <adulau@foo.be>') : ()),
);
