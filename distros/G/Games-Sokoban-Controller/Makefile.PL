use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Games::Sokoban::Controller',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Games/Sokoban/Controller.pm',
  ABSTRACT_FROM => 'lib/Games/Sokoban/Controller.pm',
  PREREQ_PM => {
    'Games::Sokoban'      => 0,
    'Test::More'          => '0.88', # for done_testing
    'Test::UseAllModules' => '0.10',
  },
  ($ExtUtils::MakeMaker::VERSION >= 6.31
    ? ( LICENSE => 'perl' )
    : ()
  ),
);
