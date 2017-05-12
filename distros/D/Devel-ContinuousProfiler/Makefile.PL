use 5.008_000;
use ExtUtils::MakeMaker;
WriteMakefile(
  ABSTRACT_FROM => 'lib/Devel/ContinuousProfiler.pm',
  AUTHOR => 'Josh Jore <jjore@cpan.org>',
  $ExtUtils::MakeMaker::VERSION >= 6.30
    ? ( LICENSE => 'perl' )
    : (),
  NAME => 'Devel::ContinuousProfiler',
  VERSION_FROM => 'lib/Devel/ContinuousProfiler.pm',
  OPTIMIZE => '-g',
);
