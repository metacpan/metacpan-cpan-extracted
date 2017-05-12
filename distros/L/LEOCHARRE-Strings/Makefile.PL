use ExtUtils::MakeMaker;

WriteMakefile(

   NAME => 'LEOCHARRE::Strings',
   
   VERSION_FROM   => 'lib/LEOCHARRE/Strings.pm',
   
   ABSTRACT_FROM  => 'lib/LEOCHARRE/Strings.pm',      
   
   LICENSE        => 'perl',   
   
   AUTHOR         => 'Leo Charre leocharre at cpan dot org',   
   
   # gen /usr/bin/pmused by Sun Apr 18 17:14:54 EDT 2010 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Exporter'                          => '5',
      'Smart::Comments'                   => '1',
      'String::Prettify'                  => '1.03',
      'String::ShellQuote'                => '1.03',
      'Test::Simple'                      => '0',
   },

);


