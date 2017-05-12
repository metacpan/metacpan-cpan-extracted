use 5.012000;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'Graph::RandomPath',
  VERSION_FROM      => 'lib/Graph/RandomPath.pm',
  PREREQ_PM         => {
    'Test::More'         =>  0,
    'Graph'              =>  0,
    'Carp'               =>  0,
  },
  ABSTRACT_FROM     => 'lib/Graph/RandomPath.pm',
  AUTHOR            => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>',
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
         url  => 'https://github.com/hoehrmann/Graph-RandomPath.git',
         web  => 'https://github.com/hoehrmann/Graph-RandomPath',
      },
    },
  },
);
