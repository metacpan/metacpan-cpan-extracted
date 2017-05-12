use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Games::Sudoku::Component::TkPlayer',
    AUTHOR         => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM   => 'lib/Games/Sudoku/Component/TkPlayer.pm',
    ABSTRACT_FROM  => 'lib/Games/Sudoku/Component/TkPlayer.pm',
    PREREQ_PM => {
        'Test::UseAllModules' => 0,
        'Games::Sudoku::Component' => 0,
        'Tk'               => 0,
        'Tk::JPEG'         => 0,
        'Tk::Splashscreen' => 0,
        'Tk::ProgressBar'  => 0,
    },
    EXE_FILES => [qw( script/tksudoku.pl )],
    ($ExtUtils::MakeMaker::VERSION >= 6.31 ?
      (LICENSE => 'perl') : ()
    ),
);
