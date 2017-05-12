use 5.012000;
use ExtUtils::MakeMaker 6.48;

WriteMakefile(
  MIN_PERL_VERSION  => 5.012000,
  NAME              => 'Graph::SomeUtils',
  VERSION_FROM      => 'lib/Graph/SomeUtils.pm',
  PREREQ_PM         => {
    'Test::More'         =>  0,
    'Graph'              =>  0,
    'List::MoreUtils'    =>  0,
  },
  ABSTRACT_FROM     => 'lib/Graph/SomeUtils.pm',
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
         url  => 'https://github.com/hoehrmann/Graph-SomeUtils.git',
         web  => 'https://github.com/hoehrmann/Graph-SomeUtils',
      },
    },
  },
);
