use 5.020000;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'List::StackBy',
  VERSION_FROM      => 'lib/List/StackBy.pm',
  PREREQ_PM         => {
    'Test::More'         =>  0,
  },
  ABSTRACT_FROM     => 'lib/List/StackBy.pm',
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
         url  => 'https://github.com/hoehrmann/List-StackBy.git',
         web  => 'https://github.com/hoehrmann/List-StackBy',
      },
    },
  },
);
