use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'Devel::vscode',
  VERSION_FROM      => 'lib/Devel/vscode.pm', # finds $VERSION
  PREREQ_PM         => {
  },
  TEST_REQUIRES       => {
    'Test::More'      => 0,
    'JSON'            => 0,
  },
  ($] >= 5.005 ?
    (ABSTRACT_FROM  => 'lib/Devel/vscode.pm', # retrieve abstract from module
     AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),

  LICENSE           => 'perl',
  'dist'            => {
    PREOP     => 'chmod 600 Makefile.PL',
    TARFLAGS	=> '--group=none --owner=bjoern --mode=a+rw -cvf',
  },
  META_MERGE        => {
    'meta-spec' => { version => 2 },
    resources => {
       repository => {
         type => 'git',
         url  => 'https://github.com/hoehrmann/Devel-vscode.git',
         web  => 'https://github.com/hoehrmann/Devel-vscode',
      },
    },
  },
);
