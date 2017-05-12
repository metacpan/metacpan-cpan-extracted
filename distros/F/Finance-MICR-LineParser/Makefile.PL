use ExtUtils::MakeMaker;

WriteMakefile(
   NAME           => 'Finance::MICR::LineParser',
   VERSION_FROM   => 'lib/Finance/MICR/LineParser.pm',
   ABSTRACT_FROM  => 'lib/Finance/MICR/LineParser.pm',
   AUTHOR         => 'Leo Charre leocharre at cpan dot org',

   # gen /usr/bin/pmused by Wed Aug 26 13:59:27 EDT 2009
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Smart::Comments'                   => '1',
      'Test::Simple'                      => '0',
   },


   LICENSE => 'perl',


);


