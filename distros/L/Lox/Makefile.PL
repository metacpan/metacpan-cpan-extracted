use ExtUtils::MakeMaker;
WriteMakefile(
  ABSTRACT_FROM    => "lib/Lox.pm",
  AUTHOR           => 'David Farrell',
  EXE_FILES        => ['bin/plox'],
  LICENSE          => 'mit',
  MIN_PERL_VERSION => '5.24.0',
  NAME             => "Lox",
  PREREQ_PM        => {
    'File::Find'    => '0',
    'Getopt::Long'  => '0',
    'Test::More'    => '0',
  },
  VERSION_FROM      => "lib/Lox.pm",
  test => {RECURSIVE_TEST_FILES=>1},
  (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
        repository => {
            type => 'git',
            url  => 'https://github.com/dnmfarrell/Perl-Lox.git',
            web  => 'https://github.com/dnmfarrell/Perl-Lox',
        },
    }})
   : ()
  ),
);
