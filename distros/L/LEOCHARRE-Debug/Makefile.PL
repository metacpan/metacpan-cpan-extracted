use ExtUtils::MakeMaker;

WriteMakefile(

   NAME => 'LEOCHARRE::Debug',   
   VERSION_FROM   => 'lib/LEOCHARRE/Debug.pm',   
   ABSTRACT_FROM  => 'lib/LEOCHARRE/Debug.pm',      
   
   LICENSE        => 'perl',   
   
   AUTHOR         => 'Leo Charre leocharre at cpan dot org',   
   
   EXE_FILES => [],

   
   # gen /usr/bin/pmused by Mon Nov  9 12:08:37 EST 2009 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Test::Simple'                      => '0',
   },

);


