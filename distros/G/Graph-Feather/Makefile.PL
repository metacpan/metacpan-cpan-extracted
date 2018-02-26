use 5.022;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'Graph::Feather',
  VERSION_FROM      => 'lib/Graph/Feather.pm', # finds $VERSION
  PREREQ_PM         => {
    'DBD::SQLite' => '1.5',
    # http://www.cpantesters.org/cpan/report/e9b3793a-6bf8-1014-8785-51182680d7e9
    'DBI' => '1.635',
  },
  TEST_REQUIRES     => {
    'Test::More'      => 0,
    'List::UtilsBy'   => 0,
    'Graph::Directed' => 0,
    'JSON'            => 0,
  },
  ($] >= 5.005 ?     
    (ABSTRACT_FROM  => 'lib/Graph/Feather.pm', # retrieve abstract from module
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
         url  => 'https://github.com/hoehrmann/Graph-Feather.git',
         web  => 'https://github.com/hoehrmann/Graph-Feather',
      },
    },
  },
);

