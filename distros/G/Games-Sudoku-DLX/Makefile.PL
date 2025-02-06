use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Games::Sudoku::DLX',
  VERSION_FROM     => 'lib/Games/Sudoku/DLX.pm',
  ABSTRACT         => "Solve Sudoku type puzzles with Donald Knuth's DLX Algorithm",
  AUTHOR           => 'James Hammer',
  LICENSE          => 'freebsd',
  MIN_PERL_VERSION => '5.008004',
  PREREQ_PM        => {
    'strict'         => 1,
    'warnings'       => 1,
    'Algorithm::DLX' => 0.02,
  },
  TEST_REQUIRES => {
      Test::More => 1.302199,
  },
  test         => {TESTS => 't/*.t'},
  (eval { ExtUtils::MakeMaker->VERSION(7.70) } ? (META_MERGE => {
      'meta-spec' => { version => 0.02 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/jmh0036/perlDLXsudoku.git',
              web  => 'https://github.com/jmh0036/perlDLXsudoku',
          },
      }})
   : ()
  ),
);
