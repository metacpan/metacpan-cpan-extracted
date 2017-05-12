use ExtUtils::MakeMaker;

WriteMakefile
(
    'NAME'         => 'Games::Sudoku::Lite',
    'VERSION_FROM' => 'lib/Games/Sudoku/Lite.pm',
    'PREREQ_PM'    => { },
    (
        $] >= 5.005 ?
        (
            AUTHOR        => 'Bob O\'Neill <bobo@cpan.org>',
        ) : ()
    ),
);
