use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
   NAME  => 'IPC::Cache',
   VERSION_FROM => 'Cache.pm',
   PREREQ_PM => { IPC::ShareLite => '0.06', Storable => '0.607' },
   dist =>  {COMPRESS => 'gzip', SUFFIX => '.gz'}
);

