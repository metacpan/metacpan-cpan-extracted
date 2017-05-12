use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME          => 'Games::Nonogram',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/Games/Nonogram.pm',
  ABSTRACT_FROM => 'lib/Games/Nonogram.pm',
  PREREQ_PM     => {
    'Getopt::Long'        => 0,
    'IO::File'            => 0,
    'Storable'            => 0,
    'Test::UseAllModules' => 0,
  },
  EXE_FILES     => [ 'nonogram' ],
  ($ExtUtils::MakeMaker::VERSION >= 6.31
    ? (LICENSE => 'perl')
    : ()
  ),
);
