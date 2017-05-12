use ExtUtils::MakeMaker;

WriteMakefile(

   NAME => 'LEOCHARRE::Basename',
   
   VERSION_FROM   => 'lib/LEOCHARRE/Basename.pm',
   
   ABSTRACT_FROM  => 'lib/LEOCHARRE/Basename.pm',      
   
   LICENSE        => 'perl',   
   
   AUTHOR         => 'Leo Charre leocharre at cpan dot org',   
   
   EXE_FILES => [],

   
   # gen /usr/bin/pmused by Thu Mar 25 14:22:41 EDT 2010 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'Test::Simple'                      => '0',
   },

);


