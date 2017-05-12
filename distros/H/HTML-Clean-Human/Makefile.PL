use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'HTML::Clean::Human',
   VERSION_FROM => 'lib/HTML/Clean/Human.pm',
   ABSTRACT_FROM => 'lib/HTML/Clean/Human.pod',
   AUTHOR=> 'Leo Charre leocharre at cpan dot org',
   
   LICENSE => 'perl',

   # gen /usr/bin/pmused by Fri Nov 14 12:01:41 EST 2008 
   PREREQ_PM => {
      'Encode'                            => '2.12',
      'Exporter'                          => '5',
      'File::Which'                       => '0.05',
      'HTML::Entities'                    => '1.35',
      'LEOCHARRE::CLI'                    => '1.18',
      'LEOCHARRE::Class2'                 => '1.12',
      'Smart::Comments'                   => '1',
      'Test::Simple'                      => '0',
   },


   EXE_FILES => [qw(bin/htmlclean)],
);


