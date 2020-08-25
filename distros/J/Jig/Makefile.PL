use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'Jig',
  VERSION_FROM     => 'lib/Jig.pm',
  ABSTRACT_FROM    => 'lib/Jig.pm',
  AUTHOR           => 'James Hunt',
  LICENSE          => 'mit',
  MIN_PERL_VERSION => '5.008004',
  EXE_FILES        => [],
  PREREQ_PM        => {
    'strict'         => 0,
    'warnings'       => 0,
    'Test::More'     => 0,
    'Test::Deep'     => 0,
  },
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
      'meta-spec' => { version => 2 },
      resources => {
          repository => {
              type => 'git',
              url  => 'https://github.com/jhunt/jig.git',
              web  => 'https://github.com/jhunt/jig',
          },
      }})
   : ()
  ),
);
