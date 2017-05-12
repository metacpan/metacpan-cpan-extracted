use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'LEOCHARRE::Test',
   VERSION_FROM => 'lib/LEOCHARRE/Test.pm',


   # gen /usr/bin/pmused by Thu Oct 23 17:10:47 EDT 2008 
   PREREQ_PM => {
      'Carp'                              => '1',
      'DBD::mysql'                        => '4.008',
      'DBI'                               => '1.607',
      'Test::Builder::Module'             => '0.80',
   },


   EXE_FILES => [],
);


