use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Device::ScanShare',
   VERSION_FROM  => 'lib/Device/ScanShare.pm',
   ABSTRACT_FROM => 'lib/Device/ScanShare.pod',
   AUTHOR => 'Leo Charre leocharre at cpan dot org',
   LICENSE => 'perl',
   

   # gen /usr/bin/pmused by Tue May  5 17:15:43 EDT 2009 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'File::Path'                        => '2.07',
      'Getopt::Std'                       => '1.05',
      'LEOCHARRE::CLI'                    => '1.19',
      'Smart::Comments'                   => '1',
      'Test::Simple'                      => '0',
      'YAML'                              => '0.66',
   },

   
   LICENSE => 'perl',
   
   
   
   EXE_FILES => [qw(bin/scanshare)],

);


