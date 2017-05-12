use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Games::Sudoku::Component',
    VERSION_FROM      => 'lib/Games/Sudoku/Component.pm',
    PREREQ_PM         => {
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Games/Sudoku/Component.pm',
       AUTHOR         => 'Kenichi Ishigaki <ishigaki@cpan.org>') : ()),
);
