use 5.0005;
use ExtUtils::MakeMaker;

WriteMakefile
  (
   NAME              => 'Lingua::Identify',
   VERSION_FROM      => 'lib/Lingua/Identify.pm',
   ABSTRACT_FROM     => 'lib/Lingua/Identify.pm',
   PREREQ_PM         =>
   {
    'Class::Factory::Util' => 1.6,
    'Text::Affixes'        => 0.07,
    'Text::Ngram'          => 0.13,
   },
   'EXE_FILES'       => ['langident', 'make-lingua-identify-language'],
);
