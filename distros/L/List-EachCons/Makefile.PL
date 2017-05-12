use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'List::EachCons',
  VERSION_FROM      => 'lib/List/EachCons.pm',
  PREREQ_PM         => {
    'Test::More'         =>  0,
  },
  ABSTRACT_FROM     => 'lib/List/EachCons.pm',
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
         url  => 'https://github.com/hoehrmann/List-EachCons.git',
         web  => 'https://github.com/hoehrmann/List-EachCons',
      },
    },
  },
);
