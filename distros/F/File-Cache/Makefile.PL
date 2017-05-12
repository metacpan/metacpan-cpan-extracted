use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
   NAME  => 'File::Cache',
   VERSION_FROM => 'Cache.pm',
   dist =>  {COMPRESS => 'gzip', SUFFIX => '.gz'},
   PREREQ_PM => { Storable => '0.607',
		  Digest::MD5 => '2.09',
		  File::Spec => '0.82' }

);

