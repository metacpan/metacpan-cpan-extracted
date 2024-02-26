use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Games::Sudoku::Pdf',
    VERSION_FROM      => 'lib/Games/Sudoku/Pdf.pm',
    AUTHOR            => 'Steffen Heinrich <she@cpan.org>',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.006.0',
    PREREQ_PM         => {
      'PDF::API2'   => '2.000',
      'PDF::Table'  => '0.9.3',
      'Time::Local' => 0,
    },
    EXE_FILES => [
      'scripts/sudoku2pdf',
    ],
);
