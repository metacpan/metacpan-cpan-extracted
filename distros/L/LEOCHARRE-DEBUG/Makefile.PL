use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'LEOCHARRE::DEBUG',
	VERSION_FROM => 'lib/LEOCHARRE/DEBUG.pm',
   ABSTRACT_FROM => 'lib/LEOCHARRE/DEBUG.pm',
   LICENSE => 'perl',
   
   # gen /usr/bin/pmused by Thu Sep 10 16:31:26 EDT 2009 
   PREREQ_PM => {
      'Data::Dumper'                      => '2',
      'Term::ANSIColor'                   => '1.10',
      'Test::Simple'                      => '0',
   },
   AUTHOR => 'Leo Charre leocharre at cpan dot org',

);
