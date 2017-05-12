use 5.012000;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'Grammar::Formal',
  VERSION_FROM      => 'lib/Grammar/Formal.pm',
  PREREQ_PM         => {
    'Test::More'         =>  0,
    'Set::IntSpan'       =>  0,
    'Moose'              =>  0,
    'Modern::Perl'       =>  0,
    'MooseX::SetOnce'    =>  0,
  },
  ABSTRACT_FROM     => 'lib/Grammar/Formal.pm',
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
         url  => 'https://github.com/hoehrmann/Grammar-Formal.git',
         web  => 'https://github.com/hoehrmann/Grammar-Formal',
      },
    },
  },
);
