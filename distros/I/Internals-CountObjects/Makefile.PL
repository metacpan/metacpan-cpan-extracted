use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => 'Internals::CountObjects',
  ABSTRACT_FROM => 'lib/Internals/CountObjects.pm',
  VERSION_FROM => 'lib/Internals/CountObjects.pm',
  AUTHOR => 'Josh Jore <jjore@cpan.org>',
  $ExtUtils::MakeMaker::VERSION >= 6.30
    ? ( LICENSE => 'perl' )
    : (),
  PREREQ_PM => {
    'ExtUtils::MakeMaker' => 0,
    'Test::Simple' => 0,
  },
  OPTIMIZE => '-g',
);
