use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'HTML::Template::Default',
   VERSION_FROM => 'lib/HTML/Template/Default.pm',
   ABSTRACT_FROM => 'lib/HTML/Template/Default.pod',
   AUTHOR => 'Leo Charre leocharre at cpan dot org',
   LICENSE => 'perl',
   PREREQ_PM => {
      'HTML::Template' => '1.9',
      'LEOCHARRE::Debug' => 0,
      'Carp' => 0,
   }
);

