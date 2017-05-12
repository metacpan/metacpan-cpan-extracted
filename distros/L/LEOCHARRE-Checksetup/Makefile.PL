use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'LEOCHARRE::Checksetup',
   VERSION_FROM => 'lib/LEOCHARRE/Checksetup.pm',


   # gen /usr/bin/pmused by Mon Oct 27 14:49:33 EDT 2008 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Exporter'                          => '5',
      'File::Which'                       => '0.05',
      'Smart::Comments'                   => '1',
      'Test::Simple'                      => '0',
   },


   EXE_FILES => [],
);


