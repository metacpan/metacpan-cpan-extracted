use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Getopt::Std::Strict',
   VERSION_FROM => 'lib/Getopt/Std/Strict.pm',


   # gen /usr/bin/pmused by Wed Aug 27 10:08:06 EDT 2008 
   PREREQ_PM => {
      'Exporter'                          => '5.58',
      'Getopt::Std'                       => '1.05',
      'Test::Simple'                      => '0.74',
   },


   EXE_FILES => [],
);


