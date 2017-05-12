$^O=~/win32|mswin/i and die("OS not supported.\n");

use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'LEOCHARRE::CLI2',
   VERSION_FROM => 'lib/LEOCHARRE/CLI2.pm',
   ABSTRACT_FROM => 'lib/LEOCHARRE/CLI2.pod',
   AUTHOR => 'Leo Charre leocharre at cpan dot org',


   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Devel::Symdump'                    => '2.07',
      'Exporter'                          => '5',
      'Getopt::Std'                       => '1.05',
      'Getopt::Std::Strict'               => '1.01',
      'LEOCHARRE::Dir'                    => '1.06',
      'Smart::Comments'                   => '1',
      'Test::Simple'                      => '0',
      'YAML' => '0.66',
      'String::ShellQuote' => '1.03',
   },

   
   LICENSE => 'perl',
   
   
   
);


