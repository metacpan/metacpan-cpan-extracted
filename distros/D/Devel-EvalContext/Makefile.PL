use 5.006000;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'Devel::EvalContext',
  VERSION_FROM      => 'lib/Devel/EvalContext.pm',
  ABSTRACT_FROM     => 'lib/Devel/EvalContext.pm',
  AUTHOR            => 'Benjamin Smith <bsmith@cpan.org>',
  EXE_FILES         => ['bin/perl5i.pl'],
  PREREQ_PM         => {
    PadWalker => 1.0,
    YAML => 0.62,
    Data::Alias => 1.01,
    Test::More => 0,
  },
);
