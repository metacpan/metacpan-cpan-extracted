use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Games::Sudoku::Html',
    VERSION_FROM      => 'lib/Games/Sudoku/Html.pm',
    AUTHOR            => 'Steffen Heinrich <she@cpan.org>',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.06.0',
    PREREQ_PM         => {
      HTML::Template    => 0,
    },
    EXE_FILES => [
      'scripts/sudoku2html',
    ],
);
