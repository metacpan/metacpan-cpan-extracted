$^O=~/win32|mswin/i and die("OS not supported.\n");
use ExtUtils::MakeMaker;

WriteMakefile(

   NAME => 'LEOCHARRE::Digest',
   
   VERSION_FROM   => 'lib/LEOCHARRE/Digest.pm',
   
   ABSTRACT_FROM  => 'lib/LEOCHARRE/Digest.pm',      
   
   LICENSE        => 'perl',   
   
   AUTHOR         => 'Leo Charre leocharre at cpan dot org',   
   
   EXE_FILES => [],

   
   # gen /usr/bin/pmused by Wed Jan  6 10:50:08 EST 2010 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Exporter'                          => '5',
      'String::ShellQuote'                => '1.03',
      'Test::Simple'                      => '0',
   },

);


