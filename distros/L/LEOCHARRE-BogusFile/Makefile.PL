use ExtUtils::MakeMaker;

WriteMakefile(

   NAME => 'LEOCHARRE::BogusFile',
   
   VERSION_FROM   => 'lib/LEOCHARRE/BogusFile.pm',
   
   ABSTRACT_FROM  => 'lib/LEOCHARRE/BogusFile.pm',      
   
   LICENSE        => 'perl',   
   
   AUTHOR         => 'Leo Charre leocharre at cpan dot org',   
   
   EXE_FILES => [],

   
   # gen /usr/bin/pmused by Wed Jan  6 12:11:10 EST 2010 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'Test::Simple'                      => '0',
   },

);


