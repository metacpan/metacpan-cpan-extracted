use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'LEOCHARRE::HTML::Text',
   VERSION_FROM => 'lib/LEOCHARRE/HTML/Text.pm',
   

   # gen /usr/bin/pmused by Thu Aug 13 14:48:10 EDT 2009 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Config::Auto'                      => '0.20',
      'Exporter'                          => '5',
      'File::Which'                       => '0.05',
      'FindBin'                           => '1.47',
      'HTML::Entities'                    => '1.35',
      'LEOCHARRE::CLI'                    => '1.19',
      'LEOCHARRE::DEBUG'                  => '1.13',
      'Smart::Comments'                   => '1',
      'Test::More'                        => '0.8',
      'Test::Simple'                      => '0',
   },

   
   LICENSE => 'perl',
   
   
   
   EXE_FILES => [qw(bin/html2txt)],
);


