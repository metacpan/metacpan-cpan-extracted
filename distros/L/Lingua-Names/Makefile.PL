use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Lingua::Names',
   VERSION_FROM => 'lib/Lingua/Names.pm',
   

   # gen /usr/bin/pmused by Fri Aug  7 02:22:28 EDT 2009 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'Test::Simple'                      => '0',
   },

   
   LICENSE => 'perl',
   
   
   
   EXE_FILES => [],
);


