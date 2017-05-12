use ExtUtils::MakeMaker;

WriteMakefile(

   NAME => 'LEOCHARRE::Dir',
   
   VERSION_FROM   => 'lib/LEOCHARRE/Dir.pm',
   
   ABSTRACT_FROM  => 'lib/LEOCHARRE/Dir.pod',      
   
   LICENSE        => 'perl',   
   
   AUTHOR         => 'Leo Charre leocharre at cpan dot org',   
   
   EXE_FILES => [],

   
   # gen /usr/bin/pmused by Sun Apr 25 16:38:46 EDT 2010 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'File::Path'                        => '2.07',
      'Test::Simple'                      => '0',
   },

);


